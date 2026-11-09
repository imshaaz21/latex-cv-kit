#!/usr/bin/env python3
"""Regenerate the README preview images from the sample documents.

Only needed when the layout or the sample content changes. Requires pdftoppm
(poppler) and Pillow, neither of which the CV build itself depends on.

    cp config.example.tex config.tex && ./run.sh
    python3 docs/make-previews.py Jane_Doe_CV.pdf Jane_Doe_Cover_Letter.pdf
"""
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageFilter

DPI = 120
BG = (246, 247, 249)
BORDER = (214, 219, 226)
SHADOW = (203, 209, 217)
PAD, GAP, SHADOW_OFFSET, SHADOW_BLUR = 36, 30, 7, 9

here = Path(__file__).resolve().parent


def render(pdf: Path, tmp: Path) -> Image.Image:
    out = tmp / pdf.stem
    subprocess.run(
        ["pdftoppm", "-png", "-r", str(DPI), "-singlefile", str(pdf), str(out)],
        check=True,
    )
    return Image.open(out.with_suffix(".png")).convert("RGB")


def compose(pages: list[Image.Image]) -> Image.Image:
    height = max(p.height for p in pages)
    width = sum(p.width for p in pages) + GAP * (len(pages) - 1)
    canvas = Image.new("RGB", (width + PAD * 2, height + PAD * 2), BG)

    # Soft drop shadow, drawn on its own layer and blurred so the pages look like
    # sheets on a surface rather than images pasted onto a block of colour.
    shadow = Image.new("RGB", canvas.size, BG)
    x = PAD
    for page in pages:
        shadow.paste(
            Image.new("RGB", page.size, SHADOW),
            (x + SHADOW_OFFSET, PAD + SHADOW_OFFSET),
        )
        x += page.width + GAP
    canvas = shadow.filter(ImageFilter.GaussianBlur(SHADOW_BLUR))

    x = PAD
    for page in pages:
        bordered = Image.new("RGB", (page.width + 2, page.height + 2), BORDER)
        bordered.paste(page, (1, 1))
        canvas.paste(bordered, (x - 1, PAD - 1))
        x += page.width + GAP
    return canvas


def main() -> int:
    pdfs = [Path(a) for a in sys.argv[1:]]
    if not pdfs:
        print(__doc__)
        return 1
    with tempfile.TemporaryDirectory() as td:
        pages = [render(p, Path(td)) for p in pdfs]
    compose(pages).save(here / "preview.png", optimize=True)
    pages[0].save(here / "preview-cv.png", optimize=True)
    print(f"Wrote {here / 'preview.png'} and {here / 'preview-cv.png'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
