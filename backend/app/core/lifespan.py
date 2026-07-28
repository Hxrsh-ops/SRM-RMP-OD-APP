from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.utils.logger import logger
from app.config.settings import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and graceful shutdown tasks."""
    logger.info(
        f"Starting {settings.APP_NAME} v{settings.APP_VERSION} [{settings.ENVIRONMENT.value}]"
    )
    yield
    logger.info(f"Shutting down {settings.APP_NAME} gracefully.")
