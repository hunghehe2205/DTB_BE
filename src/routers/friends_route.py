from fastapi import HTTPException, status, Depends, APIRouter
from database.database import db_config
from models.friends import FriendModel
from pydantic import BaseModel
from typing import Optional


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


@router.delete('/friends/{user_id1}/{user_id2}/', status_code=status.HTTP_200_OK)
def delete_friend(user_id1: str, user_id2: str, model: FriendModel = Depends(get_db_connection)):
    result = model.delete_by_user_id(user_id1, user_id2)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])

    return result['message']


class FriendUpdate(BaseModel):
    user_id1: str
    user_id2: str
    status: str


@router.put('/friends', status_code=status.HTTP_200_OK)
def update_status(friend: FriendUpdate, model: FriendModel = Depends(get_db_connection)):
    result = model.update(friend.user_id1, friend.user_id2, friend.status)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])

    return result['message']


class FriendRequest(BaseModel):
    userid_1: str
    userid_2: str


@router.post('/friends', status_code=status.HTTP_200_OK)
def sent_request(data: FriendRequest, model: FriendModel = Depends(get_db_connection)):
    result = model.send_friend_request(data.userid_1, data.userid_2)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])

    return result['message']
