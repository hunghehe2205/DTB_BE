from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class FeedbackCreate(BaseModel):
    user_id: str
    book_id: str
    comment: Optional[str] = 'N/A'
    rating: float


class FeedbackResponse(BaseModel):
    user_id: str
    book_id: str
    comment: str
    rating: float
    time: datetime
