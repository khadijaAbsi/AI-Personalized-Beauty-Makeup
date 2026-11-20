
from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import AnyHttpUrl, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


BACKEND_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Image settings
    max_upload_mb: int = Field(default=10, gt=0)
    max_image_pixels: int = Field(
        default=20_000_000,
        gt=0,
    )

    # Supabase settings
    supabase_url: AnyHttpUrl | None = None
    supabase_publishable_key: str | None = None

    # Security settings
    auth_timeout_seconds: float = Field(
        default=5.0,
        gt=0,
        le=30,
    )

    face_confidence_threshold: float = Field(
        default=0.9, ge=0.0, le=1.0
    )
    face_detector_engine: Literal[
        "onnx", "tensorflow", "pytorch"
    ] = "onnx"


@lru_cache
def get_settings() -> Settings:
    return Settings()
