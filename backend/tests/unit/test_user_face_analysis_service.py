
from types import SimpleNamespace
from unittest.mock import Mock

import numpy as np
import pytest

from app.services.user_face_analysis_service import (
    UserFaceAnalysisService,
)


@pytest.fixture
def deps():
    image_rgb = np.zeros(
        (100, 80, 3),
        dtype=np.uint8,
    )

    preprocessing_result = SimpleNamespace(
        image=SimpleNamespace(
            image_rgb=image_rgb
        )
    )

    preprocessor = Mock()
    landmarker = Mock()
    parser = Mock()

    preprocessor.process.return_value = (
        preprocessing_result
    )

    landmarker.detect.return_value = SimpleNamespace(
        pixel_xy=np.zeros(
            (478, 2),
            dtype=np.float32,
        )
    )

    parser.parse.return_value = SimpleNamespace(
        label_map=np.zeros(
            (100, 80),
            dtype=np.uint8,
        )
    )

    service = UserFaceAnalysisService(
        preprocessor=preprocessor,
        landmarker=landmarker,
        face_parser=parser,
    )

    return SimpleNamespace(
        service=service,
        preprocessor=preprocessor,
        landmarker=landmarker,
        parser=parser,
        image_rgb=image_rgb,
    )


def test_successful_analysis(deps):
    result = deps.service.analyze(b"image-data")

    assert result.facial_landmarks_xy.shape == (
        478, 2
    )
    assert result.face_label_map.shape == (
        100, 80
    )

    deps.preprocessor.process.assert_called_once_with(
        b"image-data"
    )
    deps.landmarker.detect.assert_called_once_with(
        deps.image_rgb
    )
    deps.parser.parse.assert_called_once_with(
        deps.image_rgb
    )


def test_invalid_landmark_count(deps):
    deps.landmarker.detect.return_value = (
        SimpleNamespace(
            pixel_xy=np.zeros((100, 2))
        )
    )

    with pytest.raises(
        ValueError,
        match="invalid landmarks",
    ):
        deps.service.analyze(b"image-data")

    deps.parser.parse.assert_not_called()


def test_invalid_parsing_dimensions(deps):
    deps.parser.parse.return_value = (
        SimpleNamespace(
            label_map=np.zeros((50, 50))
        )
    )

    with pytest.raises(
        ValueError,
        match="invalid mask dimensions",
    ):
        deps.service.analyze(b"image-data")


def test_preprocessing_failure(deps):
    deps.preprocessor.process.side_effect = (
        ValueError("Invalid user image")
    )

    with pytest.raises(ValueError):
        deps.service.analyze(b"invalid-image")

    deps.landmarker.detect.assert_not_called()
    deps.parser.parse.assert_not_called()
