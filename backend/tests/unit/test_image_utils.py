
from io import BytesIO

import numpy as np
import pytest
from PIL import Image

from app.core.config import get_settings
from app.preprocessing.image_utils import (
    ImageValidator,
    ImageValidationError,
)


@pytest.fixture
def validator():
    return ImageValidator(get_settings())


def make_image_bytes(
    size=(100, 100),
    image_format="PNG",
):
    image = Image.new(
        "RGB",
        size,
        color=(120, 80, 60),
    )

    buffer = BytesIO()
    image.save(buffer, format=image_format)

    return buffer.getvalue()


# Test 1: Valid PNG image
def test_valid_png(validator):
    content = make_image_bytes()

    result = validator.validate(content)

    assert result.image_rgb.shape == (100, 100, 3)
    assert result.image_rgb.dtype == np.uint8
    assert result.source_format == "PNG"


# Test 2: Valid JPEG image
def test_valid_jpeg(validator):
    content = make_image_bytes(
        image_format="JPEG"
    )

    result = validator.validate(content)

    assert result.width == 100
    assert result.height == 100
    assert result.source_format == "JPEG"


# Test 3: Empty image
def test_empty_image(validator):
    with pytest.raises(
        ImageValidationError,
        match="empty",
    ):
        validator.validate(b"")


# Test 4: Invalid image data
def test_invalid_file(validator):
    with pytest.raises(ImageValidationError):
        validator.validate(b"not a real image")


# Test 5: EXIF orientation correction
def test_exif_orientation(validator):
    image = Image.new(
        "RGB",
        (10, 20),
        color=(120, 80, 60),
    )

    exif = Image.Exif()
    exif[274] = 6

    buffer = BytesIO()

    image.save(
        buffer,
        format="JPEG",
        exif=exif,
    )

    result = validator.validate(
        buffer.getvalue()
    )

    assert result.width == 20
    assert result.height == 10


# Test 6: Reject image exceeding pixel limit
def test_reject_too_many_pixels(validator):
    content = make_image_bytes(
        size=(5000, 5000)
    )

    with pytest.raises(
        ImageValidationError
    ) as exc:
        validator.validate(content)

    assert exc.value.code == "INVALID_DIMENSIONS"
