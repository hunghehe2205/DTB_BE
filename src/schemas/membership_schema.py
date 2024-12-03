from pydantic import BaseModel
from typing import Optional
from datetime import date

class MembershipUpdate(BaseModel):
    type: Optional[str] = None
    expired_day: Optional[date] = None
    remaining_books: Optional[int] = None
    
    
class MembershipResponse(BaseModel):
    user_id: str
    type: str
    expired_day: date
    remaining_books: int