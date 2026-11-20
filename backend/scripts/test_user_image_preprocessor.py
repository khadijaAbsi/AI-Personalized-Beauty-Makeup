
from pathlib import Path

from PIL import Image

from app.core.config import get_settings
from app.preprocessing.image_utils import ImageValidator
from app.preprocessing.face_detection import RetinaFaceDetector
from app.preprocessing.face_alignment import FaceAligner
from app.services.user_image_preprocessor import (
    UserImagePreprocessor,
)


ROOT = Path(__file__).resolve().parents[1]

IMAGE_PATH = ROOT / "test_images" / "test_face.jpg"

OUTPUT_PATH = (
    ROOT / "test_images" / "user_aligned_112.png"
)


def main():
    settings = get_settings()

    preprocessor = UserImagePreprocessor(
        image_validator=ImageValidator(settings),
        face_detector=RetinaFaceDetector(settings),
        face_aligner=FaceAligner(),
    )

    if not IMAGE_PATH.is_file():
        print("Test image not found:", IMAGE_PATH)
        return

    try:
        result = preprocessor.process(
            IMAGE_PATH.read_bytes()
        )

        Image.fromarray(
            result.aligned_face_112
        ).save(OUTPUT_PATH)

        print("\n===== GlowAI User Pipeline =====")
        print("Status: SUCCESS")
        print("Original size:",
              result.image.image_rgb.shape)
        print("Format:", result.image.source_format)
        print("Face bounding box:",
              result.detection.bbox)
        print("Confidence:",
              result.detection.confidence)
        print("Aligned shape:",
              result.aligned_face_112.shape)
        print("Output:", OUTPUT_PATH)

    except Exception as error:
        print("\nStatus: FAILED")
        print("Error:", type(error).__name__)
        print("Message:", str(error))


if __name__ == "__main__":
    main()
