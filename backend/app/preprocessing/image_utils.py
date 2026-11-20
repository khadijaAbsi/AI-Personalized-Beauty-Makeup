
from dataclasses import dataclass
from io import BytesIO

import numpy as np
from PIL import Image, ImageOps, UnidentifiedImageError

from app.core.config import Settings


# Optional support for HEIC / HEIF images
try:
    from pillow_heif import register_heif_opener
    register_heif_opener()
    HEIF_SUPPORTED = True
except ImportError:
    HEIF_SUPPORTED = False


ALLOWED_FORMATS = {"JPEG", "PNG", "WEBP"}

if HEIF_SUPPORTED:
    ALLOWED_FORMATS.add("HEIF")


class ImageValidationError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


@dataclass(frozen=True)
class ValidatedImage:
    image_rgb: np.ndarray
    width: int
    height: int
    source_format: str


class ImageValidator:
    """
    Validate and decode user-uploaded images.

    Input:
        Raw image bytes.

    Output:
        RGB uint8 NumPy array (H, W, 3).

    Does not save the uploaded image.
    """

    def __init__(self, settings: Settings):
        self._max_bytes = (
            settings.max_upload_mb * 1024 * 1024
        )

        self._max_pixels = settings.max_image_pixels

    def validate(self, content: bytes) -> ValidatedImage:

        # 1. Check input type
        if not isinstance(content, bytes):
            raise ImageValidationError(
                "INVALID_INPUT",
                "Image content must be bytes.",
            )

        # 2. Check empty files
        if not content:
            raise ImageValidationError(
                "EMPTY_IMAGE",
                "The uploaded image is empty.",
            )

        # 3. Check file size before decoding
        if len(content) > self._max_bytes:
            raise ImageValidationError(
                "FILE_TOO_LARGE",
                "The image exceeds the upload limit.",
            )

        try:
            # 4. Inspect the actual file content
            with Image.open(BytesIO(content)) as image:
                image_format = image.format

                if image_format not in ALLOWED_FORMATS:
                    raise ImageValidationError(
                        "UNSUPPORTED_FORMAT",
                        "Unsupported image format.",
                    )

                width, height = image.size

                if (
                    width <= 0
                    or height <= 0
                    or width * height > self._max_pixels
                ):
                    raise ImageValidationError(
                        "INVALID_DIMENSIONS",
                        "Image dimensions are not allowed.",
                    )

                # Check file integrity
                image.verify()

            # 5. Reopen after verify()
            with Image.open(BytesIO(content)) as image:

                # Correct EXIF orientation
                corrected = ImageOps.exif_transpose(image)

                # Handle transparent images consistently
                if (
                    "A" in corrected.getbands()
                    or "transparency" in corrected.info
                ):
                    rgba = corrected.convert("RGBA")

                    background = Image.new(
                        "RGBA",
                        rgba.size,
                        (255, 255, 255, 255),
                    )

                    rgb_image = Image.alpha_composite(
                        background,
                        rgba,
                    ).convert("RGB")

                else:
                    rgb_image = corrected.convert("RGB")

                image_rgb = np.array(
                    rgb_image,
                    dtype=np.uint8,
                    copy=True,
                )

        except ImageValidationError:
            raise

        except (
            UnidentifiedImageError,
            OSError,
            ValueError,
            Image.DecompressionBombError,
        ) as error:
            raise ImageValidationError(
                "CORRUPTED_IMAGE",
                "Cannot decode the uploaded image.",
            ) from error

        return ValidatedImage(
            image_rgb=image_rgb,
            width=image_rgb.shape[1],
            height=image_rgb.shape[0],
            source_format=image_format,
        )
