
import numpy as np
import pytest

from app.preprocessing.face_alignment import (
    FaceAligner,
    FaceAlignmentError,
    ARCFACE_TEMPLATE,
)
from app.preprocessing.face_detection import FaceDetectionResult


class TestFaceAligner:

    def test_output_size_and_type(self):
        image = np.zeros((112, 112, 3), dtype=np.uint8)

        detection = FaceDetectionResult(
            bbox=(0, 0, 111, 111),
            landmarks_5=ARCFACE_TEMPLATE.copy(),
            confidence=0.99,
        )

        result = FaceAligner().align(image, detection)

        assert result.aligned_face_112.shape == (
            112, 112, 3
        )
        assert result.aligned_face_112.dtype == np.uint8
        assert result.transformation_matrix.shape == (
            2, 3
        )

    def test_invalid_landmarks(self):
        image = np.zeros((256, 256, 3), dtype=np.uint8)

        detection = FaceDetectionResult(
            bbox=(0, 0, 100, 100),
            landmarks_5=np.zeros((3, 2)),
            confidence=0.99,
        )

        with pytest.raises(FaceAlignmentError):
            FaceAligner().align(image, detection)
