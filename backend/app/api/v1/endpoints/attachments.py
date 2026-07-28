from fastapi import APIRouter, Depends, UploadFile, File
from ....services.storage_service import LocalStorageProvider
from ....schemas.attachment import AttachmentBase
from ...dependencies import get_current_user
from ....models.user import User

router = APIRouter()

@router.post("/upload", response_model=AttachmentBase)
async def upload_attachment(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    storage_provider = LocalStorageProvider()
    metadata = await storage_provider.upload_file(file, uploaded_by=current_user.full_name)
    return metadata
