import os
import uuid
from abc import ABC, abstractmethod
from datetime import datetime, timezone
from fastapi import UploadFile, HTTPException, status
from ..core.config import settings

ALLOWED_EXTENSIONS = {".pdf", ".png", ".jpg", ".jpeg"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB limit

class StorageProvider(ABC):
    @abstractmethod
    async def upload_file(self, file: UploadFile, uploaded_by: str, document_category: str = "supporting_document") -> dict:
        """Upload file and return metadata dictionary."""
        pass

class LocalStorageProvider(StorageProvider):
    def __init__(self, upload_dir: str = settings.UPLOAD_DIR):
        self.upload_dir = upload_dir
        os.makedirs(self.upload_dir, exist_ok=True)

    async def upload_file(self, file: UploadFile, uploaded_by: str, document_category: str = "supporting_document") -> dict:
        raw_filename = os.path.basename(file.filename or "attachment")
        ext = os.path.splitext(raw_filename)[1].lower()

        if ext not in ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported file format '{ext}'. Allowed formats: PDF, PNG, JPEG."
            )

        contents = await file.read()
        size_bytes = len(contents)

        if size_bytes > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File size exceeds maximum allowed limit of 10 MB."
            )

        unique_name = f"{uuid.uuid4()}{ext}"
        file_path = os.path.join(self.upload_dir, unique_name)

        with open(file_path, "wb") as f:
            f.write(contents)

        file_url = f"/uploads/{unique_name}"
        file_type = "pdf" if ext == ".pdf" else "image"

        return {
            "file_name": raw_filename,
            "file_type": file_type,
            "size_bytes": size_bytes,
            "file_url": file_url,
            "uploaded_by": uploaded_by,
            "uploaded_at": datetime.now(timezone.utc),
            "document_category": document_category,
        }
