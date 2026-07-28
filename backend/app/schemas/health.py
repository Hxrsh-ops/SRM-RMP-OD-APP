from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """Health check endpoint response schema."""

    status: str = Field(..., example="healthy")
    version: str = Field(..., example="1.0.0")
    uptime: float = Field(..., example=124.5, description="Uptime in seconds")


class VersionResponse(BaseModel):
    """Application version endpoint response schema."""

    application: str = Field(..., example="SRM RMP OD API")
    version: str = Field(..., example="1.0.0")
    environment: str = Field(..., example="DEVELOPMENT")
