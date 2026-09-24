from pydantic import BaseModel, Field


class ReportCreate(BaseModel):
    target_type: str = Field(pattern=r"^(post|user|comment)$")
    target_id: int
    reason: str = Field(min_length=2, max_length=64)
    details: str = Field(default="", max_length=500)


class ReportResponse(BaseModel):
    id: int
    status: str


class BlockState(BaseModel):
    username: str
    blocked: bool
