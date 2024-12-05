
from fastapi import HTTPException, status, Depends, APIRouter

from database.database import db_config
from models.user import UserModel
from schemas.user_schema import UserCreate, UserResponse, UserUpdate, FullUserResponse, TransactUserID, MemUserID
from pydantic import BaseModel

router = APIRouter()


def get_connection():
    return UserModel(db_config=db_config)


@router.post('/users/', status_code=status.HTTP_201_CREATED)
def register(user: UserCreate, user_model: UserModel = Depends(get_connection)):
    response = user_model.create_user(
        user.fname, user.email, user.username, user.password, user.phonenumber)
    if 'error' in response:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=response["error"])

    return response['message']


@router.delete('/users/{user_id}', status_code=status.HTTP_204_NO_CONTENT)
def delete_user_by_id(user_id: str, user_model: UserModel = Depends(get_connection)):
    result = user_model.delete_user(user_id=user_id)
    if "error" in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])
    return result['message']


@router.put('/users/{user_id}', status_code=status.HTTP_200_OK)
def update_user(user_id: str, user_update: UserUpdate, user_model: UserModel = Depends(get_connection)):
    result = user_model.update_user(user_id=user_id, fname=user_update.fname,
                                    email=user_update.email,
                                    username=user_update.username, password=user_update.password,
                                    phonenumber=user_update.phonenumber)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])

    return result['message']


'''
@router.get('/users/{user_id}', status_code=status.HTTP_200_OK, response_model=UserResponse)
def get_user_by_id(user_id: str, user_model: UserModel = Depends(get_connection)):
    result = user_model.get_user_by_id(user_id=user_id)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])
    res = UserResponse(user_id=user_id, fname=result['FullName'],
                       email=result['Email'],
                       username=result['UserName'], phonenumber=result['PhoneNumber'], streak=result['Streak'])
    return res
'''


@router.get('/users', status_code=status.HTTP_200_OK, response_model=list[UserResponse])
def get_user_list(user_model: UserModel = Depends(get_connection)):
    user_list = user_model.get_user_list()
    res = []
    if 'error' in user_list:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=user_list["error"])
    else:
        for result in user_list:
            user = UserResponse(user_id=result['UserID'], fname=result['FullName'],
                                email=result['Email'],
                                username=result['UserName'], phonenumber=result['PhoneNumber'], streak=result['Streak'])
            res.append(user)
    return res


@router.get('/users/{user_id}', response_model=FullUserResponse, status_code=status.HTTP_200_OK)
def get_full_user(user_id: str, user: UserModel = Depends(get_connection)):
    result = user.get_full_user(user_id)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])

    user_res = UserResponse(user_id=user_id, fname=result['FullName'],
                            email=result['Email'],
                            username=result['UserName'], phonenumber=result['PhoneNumber'], streak=result['Streak'])

    trans = TransactUserID(transactionID=result['TransactionID'],
                           transactionDate=result['TransactionDate'])

    mem = MemUserID(type=result['Type'],
                    expired_date=result['ExpiredDay'],
                    remaining_books=result['RemainingBooks'])

    response = FullUserResponse(user_info=user_res,
                                transact_info=trans,
                                mem_info=mem)

    return response


class Login(BaseModel):
    user_name: str
    password: str


@router.post('/login', status_code=status.HTTP_200_OK)
def log_in(info: Login, user_model: UserModel = Depends(get_connection)):
    result = user_model.log_in(info.user_name, info.password)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])

    return result
