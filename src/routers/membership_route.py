from fastapi import HTTPException, status, Depends, APIRouter

from database.database import db_config
from models.membership import MembershipModel
from schemas.membership_schema import MembershipResponse, MembershipUpdate

router = APIRouter()


def get_connection():
    return MembershipModel(db_config=db_config)


@router.put('/membership/{user_id}', status_code=status.HTTP_200_OK)
def update_membership(user_id: str, membership_update: MembershipUpdate, membership_model: MembershipModel = Depends(get_connection)):
    result = membership_model.update_membership(user_id=user_id, type=membership_update.type,
                                                expired_day=membership_update.expired_day, remainning_books=membership_update.remaining_books)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])

    return result['message']

@router.get('/membership/{user_id}', response_model=MembershipResponse,status_code=status.HTTP_200_OK)
def get_membership(user_id:str, membership_model:MembershipModel=Depends(get_connection)):
    result = membership_model.get_membership_by_user_id(user_id=user_id)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])
    
    res = MembershipResponse(user_id=user_id, type=result['Type'],expired_day=result['ExpiredDay'],
                             remaining_books=result['RemainingBooks'])
    return res

@router.get('/membership',response_model=list[MembershipResponse],status_code=status.HTTP_200_OK)
def get_membership_list(membership_model:MembershipModel=Depends(get_connection)):
    res = membership_model.get_membership_list()
    mem_list = []
    if 'error' in res:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=res["error"])
        
    else:
        for result in res:
            mem = MembershipResponse(user_id=result['UserID'], type=result['Type'],expired_day=result['ExpiredDay'],
                             remaining_books=result['RemainingBooks'])
            mem_list.append(mem)
            
    return mem_list