
from types import SimpleNamespace
from unittest.mock import Mock

import numpy as np
import pytest

from app.preprocessing.image_utils import ImageValidationError
from app.preprocessing.face_detection import (
    NoFaceDetectedError,
    MultipleFacesDetectedError,
)
from app.services.user_image_preprocessor import (
    UserImagePreprocessor,
)


@pytest.fixture
def deps():

    image_rgb = np.zeros(
        (100, 100, 3),
        dtype=np.uint8,
    )

    image = SimpleNamespace(
        image_rgb=image_rgb,
        width=100,
        height=100,
        source_format="JPEG",
    )

    detection = SimpleNamespace(
        bbox=(10, 10, 90, 90),
        landmarks_5=np.zeros((5, 2)),
        confidence=0.99,
    )

    alignment = SimpleNamespace(
        aligned_face_112=np.zeros(
            (112, 112, 3),
            dtype=np.uint8,
        ),
        transformation_matrix=np.eye(
            2, 3, dtype=np.float32
        ),
    )

    validator = Mock()
    detector = Mock()
    aligner = Mock()

    validator.validate.return_value = image
    detector.detect.return_value = detection
    aligner.align.return_value = alignment

    service = UserImagePreprocessor(
        image_validator=validator,
        face_detector=detector,
        face_aligner=aligner,
    )

    return SimpleNamespace(
        service=service,
        validator=validator,
        detector=detector,
        aligner=aligner,
        image=image,
        detection=detection,
        alignment=alignment,
    )


def test_valid_single_face(deps):
    result = deps.service.process(b"image-bytes")

    assert result.image is deps.image
    assert result.detection is deps.detection
    assert result.aligned_face_112.shape == (
        112, 112, 3
    )

    deps.validator.validate.assert_called_once()
    deps.detector.detect.assert_called_once_with(
        deps.image.image_rgb
    )
    deps.aligner.align.assert_called_once_with(
        deps.image.image_rgb,
        deps.detection,
    )


def test_invalid_image(deps):
    deps.validator.validate.side_effect = (
        ImageValidationError(
            "CORRUPTED_IMAGE",
            "Invalid image",
        )
    )

    with pytest.raises(ImageValidationError):
        deps.service.process(b"invalid-data")

    deps.detector.detect.assert_not_called()
    deps.aligner.align.assert_not_called()


def test_no_face(deps):
    deps.detector.detect.side_effect = (
        NoFaceDetectedError("No face detected")
    )

    with pytest.raises(NoFaceDetectedError):
        deps.service.process(b"image-data")

    deps.aligner.align.assert_not_called()


def test_multiple_faces(deps):
    deps.detector.detect.side_effect = (
        MultipleFacesDetectedError(
            "Multiple faces detected"
        )
    )

    with pytest.raises(MultipleFacesDetectedError):
        deps.service.process(b"image-data")

    deps.aligner.align.assert_not_called()
