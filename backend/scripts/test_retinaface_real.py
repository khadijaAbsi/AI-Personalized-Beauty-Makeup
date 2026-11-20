
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps

from app.core.config import get_settings
from app.preprocessing.face_detection import RetinaFaceDetector
from app.preprocessing.face_alignment import FaceAligner

def main():
    image_path = Path(sys.argv[1])

    with Image.open(image_path) as image:
        image = ImageOps.exif_transpose(image)
        rgb = np.asarray(
            image.convert("RGB"),
            dtype=np.uint8,
        )

    detector = RetinaFaceDetector(get_settings())
    result = detector.detect(rgb)

    print("Face detected successfully!")
    print("Bounding Box:", result.bbox)
    print("Confidence:", result.confidence)
    print("Landmarks:", result.landmarks_5)

    # Align the detected face for ArcFace
    aligner = FaceAligner()
    alignment = aligner.align(rgb, result)

    # Save the aligned RGB image
    output_path = Path("test_images/aligned_face_112.png")

    Image.fromarray(
        alignment.aligned_face_112
    ).save(output_path)

    print("Alignment successful!")
    print("Aligned shape:", alignment.aligned_face_112.shape)
    print("Saved to:", output_path)



if __name__ == "__main__":
    main()
