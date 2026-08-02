from typing import Optional
from fastapi import APIRouter, Depends, UploadFile, File, Form
from ....services.storage_service import LocalStorageProvider
from ....schemas.attachment import AttachmentCreate
from ...dependencies import get_current_user
from ....models.user import User

router = APIRouter()

@router.post("/upload", response_model=AttachmentCreate)
async def upload_attachment(
    file: UploadFile = File(...),
    document_category: Optional[str] = Form("supporting_document"),
    current_user: User = Depends(get_current_user)
):
    storage_provider = LocalStorageProvider()
    metadata = await storage_provider.upload_file(
        file=file,
        uploaded_by=current_user.full_name,
        document_category=document_category or "supporting_document"
    )
    return AttachmentCreate(**metadata)
