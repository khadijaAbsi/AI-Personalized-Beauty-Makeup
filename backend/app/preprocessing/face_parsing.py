
from dataclasses import dataclass
from enum import IntEnum
from pathlib import Path

import cv2
import numpy as np
import onnxruntime as ort

from app.core.config import BACKEND_DIR


MODEL_SIZE = 512
NUM_CLASSES = 19

DEFAULT_MODEL_PATH = (
    BACKEND_DIR
    / "model_weights"
    / "face-parsing-bisenet.onnx"
)


class FacePart(IntEnum):
    BACKGROUND = 0
    SKIN = 1
    LEFT_BROW = 2
    RIGHT_BROW = 3
    LEFT_EYE = 4
    RIGHT_EYE = 5
    EYEGLASSES = 6
    LEFT_EAR = 7
    RIGHT_EAR = 8
    EARRING = 9
    NOSE = 10
    MOUTH = 11
    UPPER_LIP = 12
    LOWER_LIP = 13
    NECK = 14
    NECKLACE = 15
    CLOTHES = 16
    HAIR = 17
    HAT = 18


class FaceParsingError(Exception):
    pass


@dataclass(frozen=True)
class FaceParsingResult:
    label_map: np.ndarray

    def mask_for(self, *parts: FacePart) -> np.ndarray:
        if not parts:
            raise ValueError(
                "Specify at least one face part."
            )

        labels = [int(part) for part in parts]
        return np.isin(self.label_map, labels)


class BiSeNetFaceParser:
    """Segment an RGB face image into 19 semantic classes."""

    def __init__(
        self,
        model_path: Path = DEFAULT_MODEL_PATH,
        session=None,
    ):
        if session is None:
            if not model_path.is_file():
                raise FileNotFoundError(
                    f"BiSeNet model not found: {model_path}"
                )

            session = ort.InferenceSession(
                str(model_path),
                providers=["CPUExecutionProvider"],
            )

        self._session = session
        self._input_name = session.get_inputs()[0].name
        self._output_name = session.get_outputs()[0].name

        self._mean = np.array(
            [0.485, 0.456, 0.406],
            dtype=np.float32,
        )
        self._std = np.array(
            [0.229, 0.224, 0.225],
            dtype=np.float32,
        )

    def parse(
        self,
        image_rgb: np.ndarray,
    ) -> FaceParsingResult:

        if (
            not isinstance(image_rgb, np.ndarray)
            or image_rgb.ndim != 3
            or image_rgb.shape[2] != 3
            or image_rgb.dtype != np.uint8
            or image_rgb.size == 0
        ):
            raise FaceParsingError(
                "Expected a nonempty RGB uint8 image."
            )

        height, width = image_rgb.shape[:2]

        resized = cv2.resize(
            image_rgb,
            (MODEL_SIZE, MODEL_SIZE),
            interpolation=cv2.INTER_LINEAR,
        )

        normalized = (
            resized.astype(np.float32) / 255.0
            - self._mean
        ) / self._std

        tensor = np.transpose(
            normalized,
            (2, 0, 1),
        )[np.newaxis, ...]

        tensor = np.ascontiguousarray(
            tensor,
            dtype=np.float32,
        )

        outputs = self._session.run(
            [self._output_name],
            {self._input_name: tensor},
        )

        logits = outputs[0]

        if (
            logits.ndim != 4
            or logits.shape[0] != 1
            or logits.shape[1] != NUM_CLASSES
        ):
            raise FaceParsingError(
                "Unexpected BiSeNet output shape."
            )

        labels = np.argmax(
            logits[0],
            axis=0,
        ).astype(np.uint8)

        label_map = cv2.resize(
            labels,
            (width, height),
            interpolation=cv2.INTER_NEAREST,
        )

        return FaceParsingResult(
            label_map=label_map,
        )
