
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps

from app.preprocessing.face_parsing import (
    BiSeNetFaceParser,
    FacePart,
)


def main():
    image_path = Path(sys.argv[1])

    with Image.open(image_path) as image:
        image_rgb = np.asarray(
            ImageOps.exif_transpose(image).convert("RGB"),
            dtype=np.uint8,
        )

    parser = BiSeNetFaceParser()
    result = parser.parse(image_rgb)

    print("Face parsing successful!")
    print("Label map shape:", result.label_map.shape)
    print("Detected classes:", np.unique(result.label_map))

    skin_mask = result.mask_for(FacePart.SKIN)
    lip_mask = result.mask_for(
        FacePart.UPPER_LIP,
        FacePart.LOWER_LIP,
    )

    output_dir = Path("test_images")

    Image.fromarray(
        result.label_map
    ).save(output_dir / "face_parsing_labels.png")

    Image.fromarray(
        (skin_mask.astype(np.uint8) * 255)
    ).save(output_dir / "skin_mask.png")

    Image.fromarray(
        (lip_mask.astype(np.uint8) * 255)
    ).save(output_dir / "lips_mask.png")

    print("Segmentation masks saved successfully!")


if __name__ == "__main__":
    main()
