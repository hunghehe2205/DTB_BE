from fastapi import HTTPException, status, Depends, APIRouter
from database.database import db_config
from models.friends import FriendModel
from pydantic import BaseModel


def get_db_connection():
    return FriendModel(db_config=db_config)


class FriendResponse(BaseModel):
    user_id_1: str
    user_id_2: str
    status: str


router = APIRouter()


@router.get('/friends/{user_id_1}', status_code=status.HTTP_200_OK)
def get_friend_by_user_id1(user_id_1: str, model: FriendModel = Depends(get_db_connection)):
    result = model.get_friend_list_by_user_id(user_id_1)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])

    return result
