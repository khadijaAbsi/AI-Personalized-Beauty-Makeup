
import numpy as np
import pytest

from app.preprocessing.tensor_utils import (
    FaceTensorPreparer,
)


@pytest.fixture
def preparer():
    return FaceTensorPreparer(image_size=256)


def test_valid_tensor_preparation(preparer):

    image = np.full(
        (100, 80, 3),
        128,
        dtype=np.uint8,
    )

    labels = np.zeros(
        (100, 80),
        dtype=np.uint8,
    )

    labels[20:60, 20:50] = 1

    result = preparer.prepare(image, labels)

    assert result.image_chw.shape == (
        3, 256, 256
    )

    assert result.labels_hw.shape == (
        256, 256
    )

    assert result.image_chw.dtype == np.float32
    assert result.labels_hw.dtype == np.uint8

    assert result.image_chw.min() >= -1
    assert result.image_chw.max() <= 1

    assert set(
        np.unique(result.labels_hw)
    ) == {0, 1}


def test_invalid_image_dimensions(preparer):

    image = np.zeros(
        (100, 80),
        dtype=np.uint8,
    )

    labels = np.zeros(
        (100, 80),
        dtype=np.uint8,
    )

    with pytest.raises(ValueError):
        preparer.prepare(image, labels)


def test_mismatched_segmentation(preparer):

    image = np.zeros(
        (100, 80, 3),
        dtype=np.uint8,
    )

    labels = np.zeros(
        (50, 50),
        dtype=np.uint8,
    )

    with pytest.raises(
        ValueError,
        match="dimensions mismatch",
    ):
        preparer.prepare(image, labels)


def test_invalid_class_ids(preparer):

    image = np.zeros(
        (100, 80, 3),
        dtype=np.uint8,
    )

    labels = np.full(
        (100, 80),
        99,
        dtype=np.uint8,
    )

    with pytest.raises(
        ValueError,
        match="Invalid BiSeNet",
    ):
        preparer.prepare(image, labels)
