from pydantic import BaseModel, EmailStr
from datetime import datetime, date

# Pydantic model for user registration request


class UserCreate(BaseModel):
    fname: str
    email: EmailStr
    username: str
    password: str
    phonenumber: str
# Pydantic model for user update request


class UserUpdate(BaseModel):
    fname: str = None
    email: EmailStr = None
    username: str = None
    password: str = None
    phonenumber: str = None


# Pydantic model for user response
class UserResponse(BaseModel):
    user_id: str
    fname: str
    email: EmailStr
    username: str
    phonenumber: str
    streak: int


class TransactUserID(BaseModel):
    transactionID: str
    transactionDate: datetime


class MemUserID(BaseModel):
    type: str
    expired_date: date
    remaining_books: int


class FullUserResponse(BaseModel):
    user_info: UserResponse
    transact_info: TransactUserID
    mem_info: MemUserID
