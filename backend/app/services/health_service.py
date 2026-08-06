import time
from app.core.config import settings
from app.schemas.health import HealthResponse, VersionResponse


class HealthService:
    """Service to track app uptime and compute health diagnostics."""

    _start_time: float = time.time()

    @classmethod
    def get_uptime(cls) -> float:
        """Returns uptime in seconds."""
        return round(time.time() - cls._start_time, 2)

    @classmethod
    def get_health(cls) -> HealthResponse:
        """Generates health response model."""
        return HealthResponse(
            status="healthy",
            version=settings.APP_VERSION,
            uptime=cls.get_uptime(),
        )

    @classmethod
    def get_version(cls) -> VersionResponse:
        """Generates version response model."""
        return VersionResponse(
            application=settings.APP_NAME,
            version=settings.APP_VERSION,
            environment=settings.ENVIRONMENT.value,
        )
