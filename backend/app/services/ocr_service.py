import io

from PIL import Image
from pix2tex.cli import LatexOCR

_model = None


def _get_model():
    global _model
    if _model is None:
        _model = LatexOCR()
    return _model


def image_to_latex(image_bytes: bytes) -> str:
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    return _get_model()(image)
