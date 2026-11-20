
import os
from dataclasses import dataclass
from typing import Callable

import cv2
import numpy as np

from app.core.config import Settings


class FaceDetectionError(Exception):
    pass


class NoFaceDetectedError(FaceDetectionError):
    pass


class MultipleFacesDetectedError(FaceDetectionError):
    pass


@dataclass(frozen=True)
class FaceDetectionResult:
    bbox: tuple[int, int, int, int]
    landmarks_5: np.ndarray
    confidence: float


class RetinaFaceDetector:
    def __init__(
        self,
        settings: Settings,
        detect_fn: Callable | None = None,
    ):
        self._threshold = (
            settings.face_confidence_threshold
        )

        if detect_fn is None:
            os.environ["DEEPFACE_BACKEND_ENGINE"] = (
                settings.face_detector_engine
            )
            from retinaface import RetinaFace
            detect_fn = RetinaFace.detect_faces

        self._detect_fn = detect_fn

    def detect(
        self,
        image_rgb: np.ndarray,
    ) -> FaceDetectionResult:

        if (
            not isinstance(image_rgb, np.ndarray)
            or image_rgb.ndim != 3
            or image_rgb.shape[2] != 3
            or image_rgb.dtype != np.uint8
            or image_rgb.size == 0
        ):
            raise ValueError(
                "Expected a nonempty RGB uint8 image."
            )

        image_bgr = cv2.cvtColor(
            image_rgb, cv2.COLOR_RGB2BGR
        )

        faces = self._detect_fn(
            image_bgr,
            threshold=self._threshold,
        )

        if not isinstance(faces, dict):
            raise FaceDetectionError(
                "Invalid detector response."
            )

        if not faces:
            raise NoFaceDetectedError(
                "No face detected."
            )

        if len(faces) > 1:
            raise MultipleFacesDetectedError(
                "Exactly one face is required."
            )

        face = next(iter(faces.values()))
        landmarks = face["landmarks"]

        # Order points by image coordinates.
        eyes = sorted(
            [
                landmarks["left_eye"],
                landmarks["right_eye"],
            ],
            key=lambda p: p[0],
        )

        mouth = sorted(
            [
                landmarks["mouth_left"],
                landmarks["mouth_right"],
            ],
            key=lambda p: p[0],
        )

        points = np.asarray(
            [
                eyes[0],
                eyes[1],
                landmarks["nose"],
                mouth[0],
                mouth[1],
            ],
            dtype=np.float32,
        )

        bbox = tuple(
            int(v) for v in face["facial_area"]
        )

        if points.shape != (5, 2) or not np.isfinite(points).all():
            raise FaceDetectionError(
                "Invalid facial landmarks."
            )

        return FaceDetectionResult(
            bbox=bbox,
            landmarks_5=points,
            confidence=float(face["score"]),
        )
