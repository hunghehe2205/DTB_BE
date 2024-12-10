from fastapi import HTTPException, status, Depends, APIRouter
from database.database import db_config
from models.access import AccessModel
from pydantic import BaseModel


def get_connection():
    return AccessModel(db_config=db_config)


router = APIRouter()


class AccessCreate(BaseModel):
    user_id: str
    book_id: str


@router.post('/access', status_code=status.HTTP_201_CREATED)
def insert_access(access: AccessCreate, access_model: AccessModel = Depends(get_connection)):
    response = access_model.insert_transaction(access.user_id, access.book_id)

    if 'error' in response:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=response["error"])

    return response['message']


@router.get('/access/{user_id}', status_code=status.HTTP_200_OK)
def get_access_book(user_id: str, model: AccessModel = Depends(get_connection)):
    result = model.get_access(user_id)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])

    return result
