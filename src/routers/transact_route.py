from fastapi import HTTPException, status, Depends, APIRouter

from database.database import db_config
from models.transaction import TransactModel
from schemas.transact_schema import TransactionCreate, TransactResponse, TransactUpdate

router = APIRouter()


def get_connection():
    return TransactModel(db_config=db_config)


@router.post('/memberships/', status_code=status.HTTP_201_CREATED)
def create_transact(trans: TransactionCreate, trans_model: TransactModel = Depends(get_connection)):
    response = trans_model.create_transact(trans.user_id, trans.type)
    if 'error' in response:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=response["error"])

    return response['message']
