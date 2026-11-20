
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps


IMAGE_DIR = Path("test_images")

COLORS = np.array([
    [0, 0, 0],        # Background
    [245, 190, 160],  # Skin
    [255, 80, 80],    # Left eyebrow
    [255, 140, 80],   # Right eyebrow
    [80, 190, 255],   # Left eye
    [60, 130, 255],   # Right eye
    [170, 100, 255],  # Glasses
    [255, 210, 90],   # Left ear
    [220, 190, 70],   # Right ear
    [150, 80, 180],   # Earring
    [255, 220, 120],  # Nose
    [180, 80, 80],    # Mouth
    [255, 40, 130],   # Upper lip
    [240, 100, 180],  # Lower lip
    [130, 220, 170],  # Neck
    [120, 180, 120],  # Necklace
    [70, 100, 180],   # Clothes
    [120, 80, 100],   # Hair
    [170, 170, 170],  # Hat
], dtype=np.uint8)


def main():
    labels = np.asarray(
        Image.open(IMAGE_DIR / "face_parsing_labels.png"),
        dtype=np.uint8,
    )

    with Image.open(IMAGE_DIR / "test_face.jpg") as image:
        original = np.asarray(
            ImageOps.exif_transpose(image).convert("RGB"),
            dtype=np.uint8,
        )

    if labels.shape != original.shape[:2]:
        raise ValueError("Image and segmentation sizes differ.")

    if labels.max() >= len(COLORS):
        raise ValueError("Unknown segmentation class.")

    colored = COLORS[labels]

    overlay = (
        0.55 * original.astype(np.float32)
        + 0.45 * colored.astype(np.float32)
    ).astype(np.uint8)

    Image.fromarray(colored).save(
        IMAGE_DIR / "face_parsing_colored.png"
    )

    Image.fromarray(overlay).save(
        IMAGE_DIR / "face_parsing_overlay.png"
    )

    print("Colored parsing preview saved!")
    print("Overlay preview saved!")


if __name__ == "__main__":
    main()
