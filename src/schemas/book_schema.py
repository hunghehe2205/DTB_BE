from pydantic import BaseModel
from typing import Optional
from datetime import date


class BookCreate(BaseModel):
    title: str
    author: str
    publication_date: date
    release_date: date


class BookResponse(BaseModel):
    bookid: str
    title: str
    publication_date: date
    rating: float
    release_date: date


class BookUpdate(BaseModel):
    title: Optional[str] = None
    author: Optional[str] = None
    publication_date: Optional[date] = None
    rating: Optional[float] = None
    release_date: Optional[date] = None
