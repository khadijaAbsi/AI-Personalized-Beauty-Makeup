
from dataclasses import dataclass, field

import numpy as np

from app.services.user_image_preprocessor import (
    UserImagePreprocessor,
    UserFaceResult,
)

from app.preprocessing.facial_landmarks import (
    MediaPipeFacialLandmarker,
)

from app.preprocessing.face_parsing import (
    BiSeNetFaceParser,
)

from app.services.facial_mask_service import (
    FacialMaskService,
)


@dataclass(frozen=True)
class UserFaceAnalysisResult:

    preprocessing: UserFaceResult

    facial_landmarks_xy: np.ndarray

    face_label_map: np.ndarray

    facial_masks: dict[str, np.ndarray] = field(
        default_factory=dict
    )


class UserFaceAnalysisService:
    """
    GlowAI user face analysis pipeline.

    1. Image validation
    2. RetinaFace detection
    3. Face alignment
    4. MediaPipe landmarks
    5. BiSeNet face parsing
    6. Facial masks extraction
    """

    def __init__(
        self,
        preprocessor: UserImagePreprocessor,
        landmarker: MediaPipeFacialLandmarker,
        face_parser: BiSeNetFaceParser,
        mask_service: FacialMaskService | None = None,
    ):
        self._preprocessor = preprocessor
        self._landmarker = landmarker
        self._parser = face_parser
        self._mask_service = mask_service

    def analyze(
        self,
        image_bytes: bytes,
    ) -> UserFaceAnalysisResult:

        # Stage 1: Validation, Detection, Alignment
        preprocessing = self._preprocessor.process(
            image_bytes
        )

        original_rgb = preprocessing.image.image_rgb

        # Stage 2: MediaPipe landmarks
        landmarks_result = self._landmarker.detect(
            original_rgb
        )

        points = np.asarray(
            landmarks_result.pixel_xy,
            dtype=np.float32,
        )

        if points.shape != (478, 2):
            raise ValueError(
                "MediaPipe returned invalid landmarks."
            )

        if not np.isfinite(points).all():
            raise ValueError(
                "MediaPipe returned non-finite landmarks."
            )

        # Stage 3: BiSeNet parsing
        parsing_result = self._parser.parse(
            original_rgb
        )

        label_map = np.asarray(
            parsing_result.label_map
        )

        if label_map.shape != original_rgb.shape[:2]:
            raise ValueError(
                "BiSeNet returned invalid mask dimensions."
            )

        # Stage 4: Facial masks
        masks = {}

        if self._mask_service is not None:
            masks = self._mask_service.build(
                parsing_result
            )

        return UserFaceAnalysisResult(
            preprocessing=preprocessing,
            facial_landmarks_xy=points,
            face_label_map=label_map,
            facial_masks=masks,
        )
