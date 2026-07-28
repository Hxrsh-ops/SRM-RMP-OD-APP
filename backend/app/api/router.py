from fastapi import APIRouter, status
from app.schemas.health import HealthResponse, VersionResponse
from app.services.health_service import HealthService

api_router = APIRouter()


@api_router.get(
    "/health",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    summary="Application Health Check",
    tags=["System"],
)
async def get_health() -> HealthResponse:
    """Returns application health status, version, and uptime."""
    return HealthService.get_health()


@api_router.get(
    "/version",
    response_model=VersionResponse,
    status_code=status.HTTP_200_OK,
    summary="Application Version",
    tags=["System"],
)
async def get_version() -> VersionResponse:
    """Returns application name, version, and environment context."""
    return HealthService.get_version()
