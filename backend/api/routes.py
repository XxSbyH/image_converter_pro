"""API 路由定义。"""

from __future__ import annotations

import base64
from typing import Any

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from config import settings
from services.image_processor import ImageProcessingError, ImageProcessor
from utils.helpers import calc_compression_ratio, normalize_format

router = APIRouter()
processor = ImageProcessor()


def _validate_common(format_value: str, quality: int) -> str:
    target_format = normalize_format(format_value)
    if target_format not in settings.ALLOWED_FORMATS:
        raise HTTPException(status_code=400, detail=f"不支持的目标格式: {target_format}")

    if not 1 <= quality <= 100:
        raise HTTPException(status_code=400, detail="quality 必须在 1 到 100 之间")

    return target_format


def _validate_dimensions(max_width: int | None, max_height: int | None) -> None:
    if max_width is not None and max_width <= 0:
        raise HTTPException(status_code=400, detail="max_width 必须大于 0")
    if max_height is not None and max_height <= 0:
        raise HTTPException(status_code=400, detail="max_height 必须大于 0")


async def _validate_file(upload_file: UploadFile) -> bytes:
    if not upload_file.filename:
        raise HTTPException(status_code=400, detail="文件名为空")

    ext = normalize_format(upload_file.filename.split(".")[-1]) if "." in upload_file.filename else ""
    if ext not in settings.ALLOWED_FORMATS:
        raise HTTPException(status_code=400, detail=f"不支持的输入格式: {ext or 'unknown'}")

    data = await upload_file.read()
    if not data:
        raise HTTPException(status_code=400, detail=f"文件为空: {upload_file.filename}")

    if len(data) > settings.MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"文件过大(>{settings.MAX_FILE_SIZE} bytes): {upload_file.filename}",
        )

    return data


@router.get("/formats")
async def get_formats() -> dict[str, list[str]]:
    formats = list(dict.fromkeys(settings.ALLOWED_FORMATS))
    return {"input": formats, "output": formats}


@router.post("/convert")
async def convert_image(
    file: UploadFile = File(...),
    format: str = Form(...),
    quality: int = Form(85),
    max_width: int | None = Form(None),
    max_height: int | None = Form(None),
) -> dict[str, Any]:
    target_format = _validate_common(format, quality)
    _validate_dimensions(max_width, max_height)
    input_bytes = await _validate_file(file)

    try:
        output_bytes = await processor.convert_image(
            input_bytes=input_bytes,
            output_format=target_format,
            quality=quality,
            max_width=max_width,
            max_height=max_height,
        )
    except ImageProcessingError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"处理失败: {exc}") from exc

    original_size = len(input_bytes)
    compressed_size = len(output_bytes)
    output_base64 = base64.b64encode(output_bytes).decode("utf-8")

    return {
        "success": True,
        "original_size": original_size,
        "compressed_size": compressed_size,
        "compression_ratio": calc_compression_ratio(original_size, compressed_size),
        "output_base64": output_base64,
    }


@router.post("/batch-convert")
async def batch_convert(
    files: list[UploadFile] = File(...),
    format: str = Form(...),
    quality: int = Form(85),
    max_width: int | None = Form(None),
    max_height: int | None = Form(None),
) -> dict[str, list[dict[str, Any]]]:
    target_format = _validate_common(format, quality)
    _validate_dimensions(max_width, max_height)
    results: list[dict[str, Any]] = []

    for file in files:
        item: dict[str, Any] = {
            "filename": file.filename or "",
            "success": False,
            "original_size": 0,
            "compressed_size": 0,
            "compression_ratio": "0%",
            "output_base64": "",
        }
        try:
            input_bytes = await _validate_file(file)
            output_bytes = await processor.convert_image(
                input_bytes=input_bytes,
                output_format=target_format,
                quality=quality,
                max_width=max_width,
                max_height=max_height,
            )

            original_size = len(input_bytes)
            compressed_size = len(output_bytes)
            item.update(
                {
                    "success": True,
                    "original_size": original_size,
                    "compressed_size": compressed_size,
                    "compression_ratio": calc_compression_ratio(original_size, compressed_size),
                    "output_base64": base64.b64encode(output_bytes).decode("utf-8"),
                }
            )
        except HTTPException as exc:
            item["error"] = exc.detail
        except ImageProcessingError as exc:
            item["error"] = str(exc)
        except Exception as exc:
            item["error"] = f"处理失败: {exc}"
        finally:
            results.append(item)

    return {"results": results}
