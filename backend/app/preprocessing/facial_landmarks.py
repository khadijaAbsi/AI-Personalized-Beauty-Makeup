
from dataclasses import dataclass

import mediapipe as mp
import numpy as np

from app.core.config import BACKEND_DIR


EXPECTED_LANDMARKS = 478

MODEL_PATH = (
    BACKEND_DIR
    / "model_weights"
    / "face_landmarker.task"
)


class FacialLandmarksError(Exception):
    pass


class NoFacialLandmarksError(FacialLandmarksError):
    pass


@dataclass(frozen=True)
class FacialLandmarksResult:
    normalized_xyz: np.ndarray
    pixel_xy: np.ndarray


class MediaPipeFacialLandmarker:
    """Extract detailed landmarks from an RGB image."""

    def __init__(self, model_path=MODEL_PATH):
        if not model_path.is_file():
            raise FileNotFoundError(
                f"MediaPipe model not found: {model_path}"
            )

        options = mp.tasks.vision.FaceLandmarkerOptions(
            base_options=mp.tasks.BaseOptions(
                model_asset_path=str(model_path)
            ),
            running_mode=mp.tasks.vision.RunningMode.IMAGE,
            num_faces=1,
            output_face_blendshapes=False,
            output_facial_transformation_matrixes=False,
        )

        self._landmarker = (
            mp.tasks.vision.FaceLandmarker
            .create_from_options(options)
        )

    def detect(
        self,
        image_rgb: np.ndarray,
    ) -> FacialLandmarksResult:

        if (
            not isinstance(image_rgb, np.ndarray)
            or image_rgb.ndim != 3
            or image_rgb.shape[2] != 3
            or image_rgb.dtype != np.uint8
            or image_rgb.size == 0
        ):
            raise FacialLandmarksError(
                "Expected a nonempty RGB uint8 image."
            )

        height, width = image_rgb.shape[:2]

        mp_image = mp.Image(
            image_format=mp.ImageFormat.SRGB,
            data=np.ascontiguousarray(image_rgb),
        )

        result = self._landmarker.detect(mp_image)

        if not result.face_landmarks:
            raise NoFacialLandmarksError(
                "MediaPipe could not locate facial landmarks."
            )

        landmarks = result.face_landmarks[0]

        normalized = np.array(
            [[p.x, p.y, p.z] for p in landmarks],
            dtype=np.float32,
        )

        if (
            normalized.shape != (EXPECTED_LANDMARKS, 3)
            or not np.isfinite(normalized).all()
        ):
            raise FacialLandmarksError(
                "Unexpected landmark output."
            )

        pixels = normalized[:, :2].copy()
        pixels[:, 0] *= width
        pixels[:, 1] *= height

        return FacialLandmarksResult(
            normalized_xyz=normalized,
            pixel_xy=pixels,
        )

    def close(self):
        self._landmarker.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()
