
from dataclasses import dataclass

import cv2
import numpy as np


@dataclass(frozen=True)
class PreparedFaceTensors:
    image_chw: np.ndarray
    labels_hw: np.ndarray


class FaceTensorPreparer:
    """
    Prepare image and segmentation tensors.

    Image output:
        Shape: (3, 256, 256)
        Type: float32
        Range: [-1, 1]

    Segmentation output:
        Shape: (256, 256)
        Type: uint8
        Values: original BiSeNet class IDs
    """

    def __init__(self, image_size: int = 256):
        if image_size <= 0:
            raise ValueError(
                "Image size must be positive."
            )

        self._size = image_size

    def prepare(
        self,
        image_rgb: np.ndarray,
        label_map: np.ndarray,
    ) -> PreparedFaceTensors:

        image = np.asarray(image_rgb)
        labels = np.asarray(label_map)

        if image.ndim != 3 or image.shape[2] != 3:
            raise ValueError(
                "Expected an RGB image (H, W, 3)."
            )

        if image.dtype != np.uint8:
            raise ValueError(
                "RGB image must have uint8 dtype."
            )

        if labels.shape != image.shape[:2]:
            raise ValueError(
                "Segmentation dimensions mismatch."
            )

        if not np.issubdtype(
            labels.dtype,
            np.integer,
        ):
            raise ValueError(
                "Segmentation labels must be integers."
            )

        if labels.min() < 0 or labels.max() > 18:
            raise ValueError(
                "Invalid BiSeNet class IDs."
            )

        size = (self._size, self._size)

        resized_image = cv2.resize(
            image,
            size,
            interpolation=cv2.INTER_LINEAR,
        )

        resized_labels = cv2.resize(
            labels.astype(np.uint8),
            size,
            interpolation=cv2.INTER_NEAREST,
        )

        # Normalize RGB to [-1, 1].
        normalized = (
            resized_image.astype(np.float32)
            / 127.5
        ) - 1.0

        # HWC -> CHW
        image_chw = np.ascontiguousarray(
            normalized.transpose(2, 0, 1)
        )

        return PreparedFaceTensors(
            image_chw=image_chw,
            labels_hw=resized_labels,
        )
