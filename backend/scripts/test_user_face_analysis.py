
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

from app.core.config import get_settings

from app.preprocessing.image_utils import ImageValidator
from app.preprocessing.face_detection import RetinaFaceDetector
from app.preprocessing.face_alignment import FaceAligner
from app.preprocessing.facial_landmarks import (
    MediaPipeFacialLandmarker,
)
from app.preprocessing.face_parsing import (
    BiSeNetFaceParser,
)

from app.services.user_image_preprocessor import (
    UserImagePreprocessor,
)
from app.services.user_face_analysis_service import (
    UserFaceAnalysisService,
)
from app.services.facial_mask_service import (
    FacialMaskService,
)


# =====================================
# Paths
# =====================================

ROOT = Path(__file__).resolve().parents[1]

IMAGE_PATH = (
    ROOT / "test_images" / "test_face.jpg"
)

OUTPUT_DIR = (
    ROOT / "test_images" / "analysis_results"
)


# =====================================
# Main Test
# =====================================

def main():

    if not IMAGE_PATH.is_file():
        print("ERROR: Image not found!")
        print(IMAGE_PATH)
        return

    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    settings = get_settings()

    # Stage 1:
    # Validation + Detection + Alignment
    preprocessor = UserImagePreprocessor(
        image_validator=ImageValidator(settings),
        face_detector=RetinaFaceDetector(settings),
        face_aligner=FaceAligner(),
    )

    # Stage 2:
    # MediaPipe + BiSeNet + Facial Masks
    with MediaPipeFacialLandmarker() as landmarker:

        service = UserFaceAnalysisService(
            preprocessor=preprocessor,
            landmarker=landmarker,
            face_parser=BiSeNetFaceParser(),
            mask_service=FacialMaskService(),
        )

        result = service.analyze(
            IMAGE_PATH.read_bytes()
        )

    # =====================================
    # Extract outputs
    # =====================================

    original_rgb = (
        result.preprocessing.image.image_rgb
    )

    aligned_face = (
        result.preprocessing.aligned_face_112
    )

    landmarks = result.facial_landmarks_xy
    label_map = result.face_label_map

    # =====================================
    # 1. Save aligned face
    # =====================================

    Image.fromarray(
        aligned_face
    ).save(
        OUTPUT_DIR / "aligned_112.png"
    )

    # =====================================
    # 2. Save MediaPipe landmarks preview
    # =====================================

    preview = Image.fromarray(original_rgb.copy())
    draw = ImageDraw.Draw(preview)

    for x, y in landmarks:

        x = int(x)
        y = int(y)

        draw.ellipse(
            (x - 1, y - 1, x + 1, y + 1),
            fill=(0, 255, 0),
        )

    preview.save(
        OUTPUT_DIR / "landmarks_preview.jpg"
    )

    # =====================================
    # 3. Save original face parsing labels
    # =====================================

    labels_uint8 = label_map.astype(
        np.uint8
    )

    Image.fromarray(
        labels_uint8
    ).save(
        OUTPUT_DIR / "face_label_map.png"
    )

    # =====================================
    # 4. Save parsing preview
    # =====================================

    parsing_preview = np.clip(
        label_map.astype(np.uint16) * 12,
        0,
        255,
    ).astype(np.uint8)

    Image.fromarray(
        parsing_preview
    ).save(
        OUTPUT_DIR / "face_parsing_preview.png"
    )

    # =====================================
    # 5. Save facial masks
    # =====================================

    print("\n===== Facial Masks =====")

    for mask_name, mask in result.facial_masks.items():

        mask_array = np.asarray(
            mask,
            dtype=np.uint8,
        )

        if mask_array.shape != original_rgb.shape[:2]:
            raise ValueError(
                f"Invalid dimensions for {mask_name}"
            )

        output_path = (
            OUTPUT_DIR / f"mask_{mask_name}.png"
        )

        # Convert binary mask 0/1 into 0/255
        mask_image = (
            (mask_array > 0).astype(np.uint8) * 255
        )

        Image.fromarray(
            mask_image
        ).save(output_path)

        print(
            f"{mask_name}: "
            f"shape={mask_array.shape}, "
            f"pixels={int((mask_array > 0).sum())}"
        )

    # =====================================
    # Final summary
    # =====================================

    print("\n===== GlowAI Face Analysis =====")

    print("Status: SUCCESS")

    print(
        "Original shape:",
        original_rgb.shape,
    )

    print(
        "Aligned shape:",
        aligned_face.shape,
    )

    print(
        "MediaPipe landmarks:",
        landmarks.shape,
    )

    print(
        "Face parsing shape:",
        label_map.shape,
    )

    print(
        "Detected parsing classes:",
        np.unique(label_map).tolist(),
    )

    print(
        "Facial masks:",
        list(result.facial_masks.keys()),
    )

    print("\nResults saved to:")
    print(OUTPUT_DIR)


if __name__ == "__main__":
    main()
