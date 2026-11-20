
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageOps

from app.preprocessing.facial_landmarks import (
    MediaPipeFacialLandmarker,
)


def main():
    image_path = Path(sys.argv[1])

    with Image.open(image_path) as image:
        image = ImageOps.exif_transpose(image)
        image_rgb = np.asarray(
            image.convert("RGB"),
            dtype=np.uint8,
        )

    with MediaPipeFacialLandmarker() as landmarker:
        result = landmarker.detect(image_rgb)

    print("Facial landmarks detected!")
    print("Landmark count:", len(result.pixel_xy))
    print("Normalized shape:", result.normalized_xyz.shape)
    print("Pixel shape:", result.pixel_xy.shape)

    # Draw landmarks for visual verification.
    preview = cv2.cvtColor(
        image_rgb,
        cv2.COLOR_RGB2BGR,
    )

    for x, y in result.pixel_xy:
        cv2.circle(
            preview,
            (int(round(x)), int(round(y))),
            1,
            (0, 255, 0),
            -1,
        )

    output_path = Path(
        "test_images/facial_landmarks_preview.jpg"
    )

    cv2.imwrite(str(output_path), preview)

    print("Preview saved to:", output_path)


if __name__ == "__main__":
    main()
