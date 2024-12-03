from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class TransactionCreate(BaseModel):
    user_id: str
    type: str


class TransactResponse(BaseModel):
    transact_id: str
    user_id: str
    transact_date: datetime
    type: str


class TransactUpdate(BaseModel):
    user_id: Optional[str] = None
    transact_date: Optional[str] = None
    type: Optional[str] = None



