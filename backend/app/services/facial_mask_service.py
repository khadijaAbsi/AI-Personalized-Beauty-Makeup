
import numpy as np

from app.preprocessing.face_parsing import FacePart


class FacialMaskService:
    """
    Creates makeup-related masks from BiSeNet
    parsing results.

    Output masks:
        skin
        upper_lip
        lower_lip
        lips

    All masks have shape (H, W)
    and binary values 0 or 1.
    """

    @staticmethod
    def _binary_mask(parsing_result, face_part):

        label_map = np.asarray(
            parsing_result.label_map
        )

        mask = np.asarray(
            parsing_result.mask_for(face_part)
        )

        if mask.shape != label_map.shape:
            raise ValueError(
                "Facial mask dimensions do not "
                "match the parsing label map."
            )

        return (mask > 0).astype(np.uint8)

    def build(self, parsing_result):

        skin = self._binary_mask(
            parsing_result,
            FacePart.SKIN,
        )

        upper_lip = self._binary_mask(
            parsing_result,
            FacePart.UPPER_LIP,
        )

        lower_lip = self._binary_mask(
            parsing_result,
            FacePart.LOWER_LIP,
        )

        lips = np.maximum(
            upper_lip,
            lower_lip,
        )

        return {
            "skin": skin,
            "upper_lip": upper_lip,
            "lower_lip": lower_lip,
            "lips": lips,
        }
