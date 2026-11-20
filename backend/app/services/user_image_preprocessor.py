
from dataclasses import dataclass

import numpy as np

from app.preprocessing.image_utils import (
    ImageValidator,
    ValidatedImage,
)

from app.preprocessing.face_detection import (
    RetinaFaceDetector,
    FaceDetectionResult,
)

from app.preprocessing.face_alignment import FaceAligner


@dataclass(frozen=True)
class UserFaceResult:
    """
    Result of the user image preprocessing pipeline.
    """

    # Original validated image
    image: ValidatedImage

    # RetinaFace detection result
    detection: FaceDetectionResult

    # Aligned face for ArcFace (112x112 RGB)
    aligned_face_112: np.ndarray

    # Affine transformation matrix (2x3)
    transformation_matrix: np.ndarray


class UserImagePreprocessor:
    """
    Preprocessing service for user-uploaded images.

    Pipeline:
        1. Validate the uploaded image.
        2. Decode and convert it to RGB.
        3. Detect exactly one face using RetinaFace.
        4. Align the face to 112x112.
        5. Return the preprocessing results.

    MediaPipe and BiSeNet will be integrated later.
    """

    def __init__(
        self,
        image_validator: ImageValidator,
        face_detector: RetinaFaceDetector,
        face_aligner: FaceAligner,
    ):
        self._validator = image_validator
        self._detector = face_detector
        self._aligner = face_aligner

    def process(
        self,
        image_bytes: bytes,
    ) -> UserFaceResult:

        # Step 1: Validate the uploaded image
        validated_image = self._validator.validate(
            image_bytes
        )

        image_rgb = validated_image.image_rgb

        # Step 2: Detect exactly one face
        detection = self._detector.detect(
            image_rgb
        )

        # Step 3: Align the detected face
        alignment = self._aligner.align(
            image_rgb,
            detection,
        )

        # Step 4: Return all preprocessing results
        return UserFaceResult(
            image=validated_image,
            detection=detection,
            aligned_face_112=alignment.aligned_face_112,
            transformation_matrix=alignment.transformation_matrix,
        )
