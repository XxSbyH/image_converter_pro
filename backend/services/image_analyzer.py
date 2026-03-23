"""图片内容分析与推荐。"""

from __future__ import annotations

from collections import Counter
from io import BytesIO
from typing import Any

from PIL import Image, ImageFilter, ImageStat, UnidentifiedImageError

from utils.helpers import normalize_format


class ImageAnalyzeError(Exception):
    """图片分析异常。"""


class ImageAnalyzer:
    """轻量级图片分析器，不依赖额外科学计算库。"""

    def analyze_bytes(self, input_bytes: bytes, filename: str = "") -> dict[str, Any]:
        try:
            with Image.open(BytesIO(input_bytes)) as image:
                image.load()
                has_alpha = self._has_transparency(image)
                thumb = image.convert("RGB")
                thumb.thumbnail((256, 256), Image.Resampling.BICUBIC)

                color_ratio = self._color_ratio(thumb)
                edge_density = self._edge_density(thumb)
                complexity = self._complexity(thumb)
                image_type = self._detect_image_type(
                    has_alpha=has_alpha,
                    color_ratio=color_ratio,
                    edge_density=edge_density,
                    complexity=complexity,
                )
                recommendation = self._generate_recommendation(
                    image_type=image_type,
                    has_transparency=has_alpha,
                    file_size=len(input_bytes),
                    source_ext=normalize_format(filename.split(".")[-1]) if "." in filename else "",
                )
                estimated_size = self._estimate_size(
                    input_size=len(input_bytes),
                    target_format=recommendation["format"],
                    quality=int(recommendation["quality"]),
                    image_type=image_type,
                    has_transparency=has_alpha,
                )
                return {
                    "image_type": image_type,
                    "complexity": round(complexity, 3),
                    "has_transparency": has_alpha,
                    "recommendation": {
                        **recommendation,
                        "estimated_size": estimated_size,
                    },
                    "alternatives": self._build_alternatives(
                        recommendation=recommendation,
                        file_size=len(input_bytes),
                        image_type=image_type,
                        has_transparency=has_alpha,
                    ),
                }
        except UnidentifiedImageError as exc:
            raise ImageAnalyzeError("无法识别的图片文件") from exc
        except OSError as exc:
            raise ImageAnalyzeError(f"读取图片失败: {exc}") from exc

    def build_overall_recommendation(self, analyses: list[dict[str, Any]]) -> dict[str, Any]:
        if not analyses:
            return {
                "format": "jpg",
                "quality": 85,
                "reason": ["未检测到可分析图片，使用默认配置"],
                "estimated_total_size": 0,
                "estimated_reduction_percent": 0,
                "type_summary": {},
            }

        type_counter = Counter(item["image_type"] for item in analyses)
        alpha_count = sum(1 for item in analyses if item.get("has_transparency"))
        current_total = sum(int(item.get("original_size", 0)) for item in analyses)

        if alpha_count >= max(1, len(analyses) // 2):
            format_name = "png"
            quality = 100
            reason = ["多数图片包含透明通道，推荐 PNG 保留透明信息"]
        else:
            dominant_type = type_counter.most_common(1)[0][0]
            if dominant_type == "photo":
                format_name = "jpg"
                quality = 85
                reason = ["多数为摄影照片，JPG 在体积与质量上更均衡"]
            elif dominant_type == "screenshot":
                format_name = "png"
                quality = 100
                reason = ["多数为截图/文字图，PNG 可避免文字边缘损失"]
            elif dominant_type == "graphic":
                format_name = "png"
                quality = 100
                reason = ["多数为图标/图形，PNG 对纯色图形压缩效果更稳定"]
            else:
                format_name = "webp"
                quality = 85
                reason = ["内容类型混合，WebP 可获得更高压缩率"]

        estimated_total = 0
        for item in analyses:
            estimated_total += self._estimate_size(
                input_size=int(item.get("original_size", 0)),
                target_format=format_name,
                quality=quality,
                image_type=item.get("image_type", "mixed"),
                has_transparency=bool(item.get("has_transparency")),
            )

        reduction_percent = 0
        if current_total > 0:
            reduction_percent = round((1 - (estimated_total / current_total)) * 100)

        return {
            "format": format_name,
            "quality": quality,
            "reason": reason,
            "estimated_total_size": max(estimated_total, 0),
            "estimated_reduction_percent": reduction_percent,
            "type_summary": dict(type_counter),
        }

    def _detect_image_type(
        self,
        *,
        has_alpha: bool,
        color_ratio: float,
        edge_density: float,
        complexity: float,
    ) -> str:
        if has_alpha and color_ratio < 0.12:
            return "graphic"
        if edge_density > 0.22 and color_ratio < 0.18:
            return "screenshot"
        if color_ratio > 0.28 or complexity > 0.50:
            return "photo"
        if color_ratio < 0.08:
            return "graphic"
        return "mixed"

    def _generate_recommendation(
        self,
        *,
        image_type: str,
        has_transparency: bool,
        file_size: int,
        source_ext: str,
    ) -> dict[str, Any]:
        if has_transparency:
            return {
                "format": "png",
                "quality": 100,
                "reason": ["图片包含透明通道，建议使用 PNG 避免透明信息丢失"],
            }

        if image_type == "photo":
            quality = 85 if file_size > 2 * 1024 * 1024 else 90
            return {
                "format": "jpg",
                "quality": quality,
                "reason": [
                    "摄影照片使用 JPG 更省空间",
                    f"质量 {quality} 在多数场景下视觉损失较小",
                ],
            }
        if image_type == "screenshot":
            return {
                "format": "png",
                "quality": 100,
                "reason": ["截图/文字图建议使用 PNG 保持边缘清晰"],
            }
        if image_type == "graphic":
            return {
                "format": "png",
                "quality": 100,
                "reason": ["图标/图形建议使用 PNG 保持纯色与锐利边缘"],
            }

        # mixed
        if source_ext == "webp":
            return {
                "format": "webp",
                "quality": 85,
                "reason": ["原图已为 WebP，继续使用可获得稳定压缩率"],
            }
        return {
            "format": "webp",
            "quality": 85,
            "reason": ["混合内容建议优先尝试 WebP 以平衡体积和画质"],
        }

    def _build_alternatives(
        self,
        *,
        recommendation: dict[str, Any],
        file_size: int,
        image_type: str,
        has_transparency: bool,
    ) -> list[dict[str, Any]]:
        rec_format = str(recommendation["format"]).lower()
        rec_quality = int(recommendation["quality"])

        options: list[tuple[str, int, str]] = []
        if rec_format == "jpg":
            options.extend(
                [
                    ("jpg", min(rec_quality + 8, 95), "更高质量，文件略大"),
                    ("webp", rec_quality, "更小体积，兼顾画质"),
                ]
            )
        elif rec_format == "png":
            if not has_transparency:
                options.append(("webp", 88, "更小体积，适合分享传输"))
            if image_type == "photo":
                options.append(("jpg", 88, "更小体积，适合摄影照片"))
        elif rec_format == "webp":
            options.extend(
                [
                    ("jpg", 88, "兼容性更高"),
                    ("webp", 75, "更小体积，画质略降"),
                ]
            )

        alternatives: list[dict[str, Any]] = []
        seen: set[tuple[str, int]] = {(rec_format, rec_quality)}
        for fmt, quality, description in options:
            key = (fmt, quality)
            if key in seen:
                continue
            seen.add(key)
            alternatives.append(
                {
                    "format": fmt,
                    "quality": quality,
                    "description": description,
                    "estimated_size": self._estimate_size(
                        input_size=file_size,
                        target_format=fmt,
                        quality=quality,
                        image_type=image_type,
                        has_transparency=has_transparency,
                    ),
                }
            )
        return alternatives

    def _estimate_size(
        self,
        *,
        input_size: int,
        target_format: str,
        quality: int,
        image_type: str,
        has_transparency: bool,
    ) -> int:
        fmt = target_format.lower()
        q = max(1, min(quality, 100))
        quality_factor = q / 100

        if fmt == "jpg":
            base = 0.18 + 0.56 * quality_factor
            if image_type in {"photo", "mixed"}:
                factor = base
            else:
                factor = base * 1.25
        elif fmt == "webp":
            base = 0.12 + 0.46 * quality_factor
            factor = base if image_type != "graphic" else base * 1.1
        else:  # png
            if has_transparency:
                factor = 1.05
            elif image_type in {"screenshot", "graphic"}:
                factor = 0.65
            else:
                factor = 1.7

        estimated = int(max(1, input_size * factor))
        return estimated

    def _has_transparency(self, image: Image.Image) -> bool:
        return image.mode in {"RGBA", "LA"} or (
            image.mode == "P" and "transparency" in image.info
        )

    def _color_ratio(self, image: Image.Image) -> float:
        total_pixels = max(1, image.width * image.height)
        colors = image.getcolors(maxcolors=total_pixels)
        if colors is None:
            return 1.0
        unique_colors = len(colors)
        return min(1.0, unique_colors / total_pixels)

    def _edge_density(self, image: Image.Image) -> float:
        edge = image.filter(ImageFilter.FIND_EDGES).convert("L")
        hist = edge.histogram()
        total = max(1, sum(hist))
        strong = sum(hist[96:])
        return strong / total

    def _complexity(self, image: Image.Image) -> float:
        stat = ImageStat.Stat(image)
        stddev = sum(stat.stddev) / max(1, len(stat.stddev))
        return min(1.0, stddev / 64.0)
