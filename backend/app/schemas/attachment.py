from uuid import UUID
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict

class AttachmentBase(BaseModel):
    file_name: str
    file_type: str
    size_bytes: int
    file_url: str
    uploaded_by: str
    uploaded_at: datetime
    document_category: Optional[str] = "supporting_document"

class AttachmentCreate(AttachmentBase):
    pass

class AttachmentResponse(AttachmentBase):
    id: UUID
    od_request_id: str

    model_config = ConfigDict(from_attributes=True)
