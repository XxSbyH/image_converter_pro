"""图像处理核心逻辑。"""

from __future__ import annotations

from io import BytesIO
from typing import Any

from PIL import Image, UnidentifiedImageError
import pillow_heif

from utils.helpers import normalize_format

pillow_heif.register_heif_opener()


class ImageProcessingError(Exception):
    """图像处理异常。"""


class ImageProcessor:
    """图片转换服务。"""

    async def convert_image(
        self,
        input_bytes: bytes,
        output_format: str,
        quality: int = 85,
        max_width: int | None = None,
        max_height: int | None = None,
    ) -> bytes:
        fmt = normalize_format(output_format)
        quality = max(1, min(quality, 100))

        try:
            with Image.open(BytesIO(input_bytes)) as image:
                image.load()
                image = await self._handle_transparency(image, fmt)

                if max_width or max_height:
                    width = max_width or image.width
                    height = max_height or image.height
                    image.thumbnail((width, height), Image.Resampling.LANCZOS)

                output = BytesIO()
                save_kwargs: dict[str, Any] = {}

                if fmt in {"jpg", "jpeg"}:
                    save_format = "JPEG"
                    save_kwargs.update({"quality": quality, "optimize": True})
                elif fmt == "png":
                    save_format = "PNG"
                    save_kwargs.update({"optimize": True})
                elif fmt == "webp":
                    save_format = "WEBP"
                    save_kwargs.update({"quality": quality, "method": 6})
                elif fmt in {"heic", "heif"}:
                    save_format = "HEIF"
                    save_kwargs.update({"quality": quality})
                else:
                    raise ImageProcessingError(f"不支持的输出格式: {output_format}")

                image.save(output, format=save_format, **save_kwargs)
                return output.getvalue()
        except UnidentifiedImageError as exc:
            raise ImageProcessingError("无法识别的图片文件") from exc
        except OSError as exc:
            raise ImageProcessingError(f"图像处理失败: {exc}") from exc

    async def _handle_transparency(self, image: Image.Image, output_format: str) -> Image.Image:
        fmt = normalize_format(output_format)
        if fmt not in {"jpg", "jpeg"}:
            return image

        has_alpha = image.mode in {"RGBA", "LA"} or (
            image.mode == "P" and "transparency" in image.info
        )
        if not has_alpha:
            return image.convert("RGB") if image.mode != "RGB" else image

        base = Image.new("RGB", image.size, (255, 255, 255))
        alpha_image = image.convert("RGBA")
        base.paste(alpha_image, mask=alpha_image.split()[-1])
        return base

    async def get_image_info(self, input_bytes: bytes) -> dict[str, Any]:
        try:
            with Image.open(BytesIO(input_bytes)) as image:
                image.load()
                return {
                    "width": image.width,
                    "height": image.height,
                    "format": normalize_format(image.format or "unknown"),
                    "size": len(input_bytes),
                    "mode": image.mode,
                }
        except UnidentifiedImageError as exc:
            raise ImageProcessingError("无法识别的图片文件") from exc
        except OSError as exc:
            raise ImageProcessingError(f"读取图片信息失败: {exc}") from exc
