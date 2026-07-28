import os
import uuid
from abc import ABC, abstractmethod
from datetime import datetime, timezone
from fastapi import UploadFile
from ..core.config import settings

class StorageProvider(ABC):
    @abstractmethod
    async def upload_file(self, file: UploadFile, uploaded_by: str) -> dict:
        """Upload file and return metadata dictionary."""
        pass

class LocalStorageProvider(StorageProvider):
    def __init__(self, upload_dir: str = settings.UPLOAD_DIR):
        self.upload_dir = upload_dir
        os.makedirs(self.upload_dir, exist_ok=True)

    async def upload_file(self, file: UploadFile, uploaded_by: str) -> dict:
        filename = file.filename or "attachment"
        ext = os.path.splitext(filename)[1]
        unique_name = f"{uuid.uuid4()}{ext}"
        file_path = os.path.join(self.upload_dir, unique_name)

        contents = await file.read()
        size_bytes = len(contents)

        with open(file_path, "wb") as f:
            f.write(contents)

        file_url = f"/uploads/{unique_name}"
        file_type = "pdf" if ext.lower() == ".pdf" else ("image" if ext.lower() in [".jpg", ".png", ".jpeg"] else "doc")

        return {
            "file_name": filename,
            "file_type": file_type,
            "size_bytes": size_bytes,
            "file_url": file_url,
            "uploaded_by": uploaded_by,
            "uploaded_at": datetime.now(timezone.utc)
        }
