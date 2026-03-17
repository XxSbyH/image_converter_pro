"""通用辅助函数。"""


def normalize_format(file_format: str) -> str:
    fmt = file_format.lower().strip().lstrip(".")
    if fmt == "heif":
        return "heic"
    return fmt


def calc_compression_ratio(original_size: int, compressed_size: int) -> str:
    if original_size <= 0:
        return "0%"
    ratio = (1 - (compressed_size / original_size)) * 100
    ratio = max(0.0, min(100.0, ratio))
    return f"{round(ratio)}%"
