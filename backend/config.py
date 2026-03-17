"""应用配置。"""

from pydantic.v1 import BaseSettings, Field


class Settings(BaseSettings):
    """支持从环境变量读取的配置。"""

    HOST: str = Field(default="127.0.0.1")
    PORT: int = Field(default=8000)
    MAX_FILE_SIZE: int = Field(default=50 * 1024 * 1024)  # 50MB
    ALLOWED_FORMATS: list[str] = Field(
        default_factory=lambda: ["jpg", "jpeg", "png", "webp", "heic", "heif"]
    )
    CORS_ORIGINS: list[str] = Field(default_factory=lambda: ["*"])

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
