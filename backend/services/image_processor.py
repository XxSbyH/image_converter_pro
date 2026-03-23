"""图像处理核心逻辑。"""

from __future__ import annotations

import base64
from io import BytesIO
from typing import Any
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFont, PngImagePlugin, UnidentifiedImageError
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
        watermark_enabled: bool = False,
        watermark_type: str = "text",
        watermark_text: str | None = None,
        watermark_opacity: int = 30,
        watermark_position: str = "bottom_right",
        watermark_font_size: int = 24,
        watermark_image_base64: str | None = None,
        strip_metadata: bool = False,
        metadata_author: str | None = None,
        metadata_copyright: str | None = None,
        metadata_comment: str | None = None,
    ) -> bytes:
        fmt = normalize_format(output_format)
        quality = max(1, min(quality, 100))
        watermark_opacity = max(0, min(watermark_opacity, 100))
        watermark_font_size = max(8, min(watermark_font_size, 160))
        watermark_position = self._normalize_position(watermark_position)

        try:
            with Image.open(BytesIO(input_bytes)) as image:
                image.load()
                source_exif = image.info.get("exif")
                source_icc_profile = image.info.get("icc_profile")
                if strip_metadata:
                    source_exif = None
                    source_icc_profile = None
                    image = image.copy()
                    image.info.clear()

                if max_width or max_height:
                    width = max_width or image.width
                    height = max_height or image.height
                    image.thumbnail((width, height), Image.Resampling.LANCZOS)

                image = await self._handle_transparency(image, fmt)
                image = await self._apply_watermark(
                    image=image,
                    output_format=fmt,
                    enabled=watermark_enabled,
                    watermark_type=watermark_type,
                    text=watermark_text,
                    opacity=watermark_opacity,
                    position=watermark_position,
                    font_size=watermark_font_size,
                    image_base64=watermark_image_base64,
                )
                image = await self._handle_transparency(image, fmt)

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

                if not strip_metadata and source_icc_profile:
                    save_kwargs["icc_profile"] = source_icc_profile

                self._apply_metadata_options(
                    save_kwargs=save_kwargs,
                    output_format=fmt,
                    strip_metadata=strip_metadata,
                    source_exif=source_exif,
                    metadata_author=metadata_author,
                    metadata_copyright=metadata_copyright,
                    metadata_comment=metadata_comment,
                )

                image.save(output, format=save_format, **save_kwargs)
                return output.getvalue()
        except UnidentifiedImageError as exc:
            raise ImageProcessingError("无法识别的图片文件") from exc
        except OSError as exc:
            raise ImageProcessingError(f"图像处理失败: {exc}") from exc
        except ValueError as exc:
            raise ImageProcessingError(f"参数错误: {exc}") from exc

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

    async def _apply_watermark(
        self,
        *,
        image: Image.Image,
        output_format: str,
        enabled: bool,
        watermark_type: str,
        text: str | None,
        opacity: int,
        position: str,
        font_size: int,
        image_base64: str | None,
    ) -> Image.Image:
        if not enabled:
            return image

        alpha = int(255 * (max(0, min(opacity, 100)) / 100))
        if alpha <= 0:
            return image

        kind = (watermark_type or "text").strip().lower()
        work = image.convert("RGBA")
        overlay = Image.new("RGBA", work.size, (255, 255, 255, 0))

        if kind == "image" and image_base64:
            await self._draw_image_watermark(
                overlay=overlay,
                image_base64=image_base64,
                alpha=alpha,
                position=position,
            )
        else:
            text = (text or "").strip()
            if not text:
                return image
            await self._draw_text_watermark(
                source_image=work,
                overlay=overlay,
                text=text,
                alpha=alpha,
                position=position,
                font_size=font_size,
            )

        result = Image.alpha_composite(work, overlay)
        if normalize_format(output_format) in {"jpg", "jpeg"}:
            return result.convert("RGB")
        return result

    async def _draw_text_watermark(
        self,
        *,
        source_image: Image.Image,
        overlay: Image.Image,
        text: str,
        alpha: int,
        position: str,
        font_size: int,
    ) -> None:
        adaptive_font_size = self._resolve_font_size(
            requested=font_size,
            canvas_size=overlay.size,
        )
        draw = ImageDraw.Draw(overlay)
        font = self._load_font(adaptive_font_size)
        box = draw.textbbox((0, 0), text, font=font, stroke_width=1)
        text_width = max(1, box[2] - box[0])
        text_height = max(1, box[3] - box[1])
        x, y = self._resolve_position(
            canvas_size=overlay.size,
            mark_size=(text_width, text_height),
            position=position,
            margin=18,
        )

        text_color = self._choose_watermark_color(
            image=source_image,
            x=x,
            y=y,
            width=text_width,
            height=text_height,
            alpha=alpha,
        )
        shadow = (0, 0, 0, min(180, alpha + 40))
        bg_alpha = min(160, max(55, int(alpha * 1.2)))
        bg_color = (0, 0, 0, bg_alpha) if text_color[0] > 127 else (255, 255, 255, bg_alpha)
        padding_x = max(6, adaptive_font_size // 5)
        padding_y = max(4, adaptive_font_size // 6)
        draw.rounded_rectangle(
            (
                max(0, x - padding_x),
                max(0, y - padding_y),
                min(overlay.width, x + text_width + padding_x),
                min(overlay.height, y + text_height + padding_y),
            ),
            radius=max(4, adaptive_font_size // 4),
            fill=bg_color,
        )
        draw.text(
            (x + 1, y + 1),
            text,
            font=font,
            fill=shadow,
            stroke_width=1,
            stroke_fill=shadow,
        )
        draw.text(
            (x, y),
            text,
            font=font,
            fill=text_color,
            stroke_width=1,
            stroke_fill=shadow,
        )

    async def _draw_image_watermark(
        self,
        *,
        overlay: Image.Image,
        image_base64: str,
        alpha: int,
        position: str,
    ) -> None:
        payload = image_base64
        if "," in payload:
            payload = payload.split(",", 1)[1]
        raw = base64.b64decode(payload)
        with Image.open(BytesIO(raw)) as mark:
            mark.load()
            mark_rgba = mark.convert("RGBA")

        max_width = max(24, int(overlay.width * 0.22))
        max_height = max(24, int(overlay.height * 0.22))
        mark_rgba.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)

        if alpha < 255:
            alpha_channel = mark_rgba.split()[-1]
            factor = max(0.0, min(alpha / 255.0, 1.0))
            alpha_channel = ImageEnhance.Brightness(alpha_channel).enhance(factor)
            mark_rgba.putalpha(alpha_channel)

        x, y = self._resolve_position(
            canvas_size=overlay.size,
            mark_size=mark_rgba.size,
            position=position,
            margin=18,
        )
        overlay.paste(mark_rgba, (x, y), mark_rgba)

    def _apply_metadata_options(
        self,
        *,
        save_kwargs: dict[str, Any],
        output_format: str,
        strip_metadata: bool,
        source_exif: bytes | None,
        metadata_author: str | None,
        metadata_copyright: str | None,
        metadata_comment: str | None,
    ) -> None:
        author = (metadata_author or "").strip()
        copyright_text = (metadata_copyright or "").strip()
        comment = (metadata_comment or "").strip()

        if normalize_format(output_format) in {"jpg", "jpeg", "webp", "heic", "heif"}:
            exif_bytes = self._build_exif_bytes(
                source_exif=None if strip_metadata else source_exif,
                author=author,
                copyright_text=copyright_text,
                comment=comment,
            )
            if exif_bytes:
                save_kwargs["exif"] = exif_bytes
            return

        if normalize_format(output_format) == "png":
            png_info = self._build_png_info(
                author=author,
                copyright_text=copyright_text,
                comment=comment,
            )
            if png_info is not None:
                save_kwargs["pnginfo"] = png_info

    def _build_exif_bytes(
        self,
        *,
        source_exif: bytes | None,
        author: str,
        copyright_text: str,
        comment: str,
    ) -> bytes | None:
        exif = Image.Exif()
        if source_exif:
            try:
                exif.load(source_exif)
            except Exception:
                exif = Image.Exif()

        if author:
            exif[315] = author
            exif[40093] = self._to_xp_unicode(author)  # XPAuthor
        if copyright_text:
            exif[33432] = copyright_text
        if comment:
            exif[270] = comment
            exif[40092] = self._to_xp_unicode(comment)  # XPComment
        if author:
            exif[40095] = self._to_xp_unicode(author)  # XPSubject

        if len(exif) == 0:
            return None
        return exif.tobytes()

    def _build_png_info(
        self,
        *,
        author: str,
        copyright_text: str,
        comment: str,
    ) -> PngImagePlugin.PngInfo | None:
        if not author and not copyright_text and not comment:
            return None
        png_info = PngImagePlugin.PngInfo()
        if author:
            png_info.add_text("Author", author)
        if copyright_text:
            png_info.add_text("Copyright", copyright_text)
        if comment:
            png_info.add_text("Comment", comment)
        return png_info

    def _load_font(self, font_size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
        candidates = [
            Path("C:/Windows/Fonts/msyh.ttc"),
            Path("C:/Windows/Fonts/simhei.ttf"),
            Path("C:/Windows/Fonts/arial.ttf"),
        ]
        for candidate in candidates:
            if candidate.exists():
                try:
                    return ImageFont.truetype(str(candidate), size=font_size)
                except OSError:
                    continue
        return ImageFont.load_default()

    def _resolve_font_size(self, *, requested: int, canvas_size: tuple[int, int]) -> int:
        width, height = canvas_size
        short_edge = max(1, min(width, height))
        adaptive_min = max(16, int(short_edge * 0.035))
        return max(requested, adaptive_min)

    def _choose_watermark_color(
        self,
        *,
        image: Image.Image,
        x: int,
        y: int,
        width: int,
        height: int,
        alpha: int,
    ) -> tuple[int, int, int, int]:
        sample_box = (
            max(0, x),
            max(0, y),
            min(image.width, x + max(12, width)),
            min(image.height, y + max(12, height)),
        )
        try:
            sample = image.crop(sample_box).convert("RGB")
            pixels = list(sample.getdata())
            if not pixels:
                raise ValueError("empty sample")
            brightness = sum((r * 299 + g * 587 + b * 114) // 1000 for r, g, b in pixels) / len(pixels)
        except Exception:
            brightness = 127

        if brightness >= 145:
            return (20, 20, 20, max(alpha, 110))
        return (245, 245, 245, max(alpha, 110))

    def _to_xp_unicode(self, text: str) -> bytes:
        return (text + "\x00").encode("utf-16le", errors="ignore")

    def _normalize_position(self, position: str) -> str:
        allowed = {
            "top_left",
            "top_right",
            "bottom_left",
            "bottom_right",
            "center",
        }
        normalized = (position or "").strip().lower()
        if normalized in allowed:
            return normalized
        return "bottom_right"

    def _resolve_position(
        self,
        *,
        canvas_size: tuple[int, int],
        mark_size: tuple[int, int],
        position: str,
        margin: int = 16,
    ) -> tuple[int, int]:
        width, height = canvas_size
        mark_width, mark_height = mark_size
        max_x = max(0, width - mark_width - margin)
        max_y = max(0, height - mark_height - margin)

        mapping = {
            "top_left": (margin, margin),
            "top_right": (max_x, margin),
            "bottom_left": (margin, max_y),
            "bottom_right": (max_x, max_y),
            "center": (
                max(0, (width - mark_width) // 2),
                max(0, (height - mark_height) // 2),
            ),
        }
        return mapping.get(position, mapping["bottom_right"])

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
