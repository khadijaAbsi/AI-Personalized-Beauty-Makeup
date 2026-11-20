
from types import SimpleNamespace

import numpy as np
import pytest

from app.preprocessing.facial_landmarks import (
    MediaPipeFacialLandmarker,
    FacialLandmarksError,
    NoFacialLandmarksError,
)


class FakeDetector:
    def __init__(self, faces):
        self.faces = faces

    def detect(self, image):
        return SimpleNamespace(
            face_landmarks=self.faces
        )


def make_landmarker(faces):
    # Skip loading the real model during unit tests
    landmarker = object.__new__(
        MediaPipeFacialLandmarker
    )
    landmarker._landmarker = FakeDetector(faces)
    return landmarker


def test_landmarks_output():
    image = np.zeros(
        (100, 200, 3),
        dtype=np.uint8,
    )

    points = [
        SimpleNamespace(x=0.25, y=0.5, z=-0.01)
        for _ in range(478)
    ]

    landmarker = make_landmarker([points])

    result = landmarker.detect(image)

    assert result.normalized_xyz.shape == (478, 3)
    assert result.pixel_xy.shape == (478, 2)
    assert result.normalized_xyz.dtype == np.float32

    # x = 0.25 * 200, y = 0.5 * 100
    np.testing.assert_allclose(
        result.pixel_xy[0],
        [50.0, 50.0],
    )


def test_no_face_detected():
    image = np.zeros(
        (100, 200, 3),
        dtype=np.uint8,
    )

    landmarker = make_landmarker([])

    with pytest.raises(NoFacialLandmarksError):
        landmarker.detect(image)


def test_invalid_image():
    image = np.zeros(
        (100, 200),
        dtype=np.uint8,
    )

    landmarker = make_landmarker([])

    with pytest.raises(FacialLandmarksError):
        landmarker.detect(image)
