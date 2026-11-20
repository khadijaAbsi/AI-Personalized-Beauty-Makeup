
from dataclasses import dataclass

import cv2
import numpy as np

from app.preprocessing.face_detection import FaceDetectionResult


# Standard ArcFace alignment template for 112x112 images
ARCFACE_SIZE = 112

ARCFACE_TEMPLATE = np.array(
    [
        [38.2946, 51.6963],
        [73.5318, 51.5014],
        [56.0252, 71.7366],
        [41.5493, 92.3655],
        [70.7299, 92.2041],
    ],
    dtype=np.float32,
)


class FaceAlignmentError(Exception):
    """Raised when face alignment fails."""
    pass


@dataclass(frozen=True)
class FaceAlignmentResult:
    aligned_face_112: np.ndarray
    transformation_matrix: np.ndarray


class FaceAligner:
    """
    Align a detected face using its five facial landmarks.

    Input:
        image_rgb: RGB uint8 image, shape (H, W, 3)
        detection: FaceDetectionResult from RetinaFace

    Output:
        Aligned RGB uint8 image, shape (112, 112, 3)
        Affine transformation matrix, shape (2, 3)
    """

    def align(
        self,
        image_rgb: np.ndarray,
        detection: FaceDetectionResult,
    ) -> FaceAlignmentResult:

        # 1. Validate the image
        if (
            not isinstance(image_rgb, np.ndarray)
            or image_rgb.ndim != 3
            or image_rgb.shape[2] != 3
            or image_rgb.dtype != np.uint8
            or image_rgb.size == 0
        ):
            raise FaceAlignmentError(
                "Expected a nonempty RGB uint8 image."
            )

        # 2. Get the 5 landmarks from RetinaFace
        landmarks = np.asarray(
            detection.landmarks_5,
            dtype=np.float32,
        )

        # 3. Validate landmarks
        if (
            landmarks.shape != (5, 2)
            or not np.isfinite(landmarks).all()
        ):
            raise FaceAlignmentError(
                "Invalid facial landmarks."
            )

        # 4. Estimate the similarity transformation
        matrix, _ = cv2.estimateAffinePartial2D(
            landmarks,
            ARCFACE_TEMPLATE,
            method=cv2.LMEDS,
        )

        if (
            matrix is None
            or not np.isfinite(matrix).all()
        ):
            raise FaceAlignmentError(
                "Face alignment failed."
            )

        # 5. Align the face to 112x112
        aligned_face = cv2.warpAffine(
            image_rgb,
            matrix,
            (ARCFACE_SIZE, ARCFACE_SIZE),
            flags=cv2.INTER_LINEAR,
            borderMode=cv2.BORDER_CONSTANT,
            borderValue=(0, 0, 0),
        )

        # 6. Return the result
        return FaceAlignmentResult(
            aligned_face_112=aligned_face,
            transformation_matrix=matrix,
        )
