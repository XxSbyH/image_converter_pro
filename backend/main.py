"""FastAPI 应用入口。"""

from datetime import datetime
import os
import tempfile
import traceback
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.routes import router
from config import settings

app = FastAPI(
    title="Image Converter API",
    description="Image Converter Pro 后端服务",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix="/api")


@app.get("/")
async def root() -> dict[str, str]:
    return {"message": "Image Converter API"}


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "healthy"}


def _write_startup_log(message: str) -> None:
    log_path = os.path.join(tempfile.gettempdir(), "image_converter_service.log")
    with open(log_path, "a", encoding="utf-8") as log_file:
        log_file.write(f"[{datetime.now().isoformat()}] {message}\n")


def main() -> None:
    _write_startup_log("service main start")
    _write_startup_log(f"host={settings.HOST}, port={settings.PORT}")
    try:
        uvicorn.run(
            app,
            host=settings.HOST,
            port=settings.PORT,
            reload=False,
            log_config=None,
            access_log=False,
        )
    except Exception as exc:
        _write_startup_log(f"service crashed: {exc}")
        _write_startup_log(traceback.format_exc())
        raise
    finally:
        _write_startup_log("service main exit")


if __name__ == "__main__":
    main()
