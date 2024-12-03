from fastapi import HTTPException, status, Depends, APIRouter
from database.database import db_config
from models.feedback import FeedbackModel
from schemas.feedback_schema import FeedbackCreate, FeedbackResponse


def get_connection():
    return FeedbackModel(db_config=db_config)


router = APIRouter()


@router.post('/feedback/', status_code=status.HTTP_201_CREATED)
def create_feedback(fb_create: FeedbackCreate, fb_model: FeedbackModel = Depends(get_connection)):
    response = fb_model.create_feedback(fb_create.user_id, fb_create.book_id,
                                        fb_create.comment, fb_create.rating)

    if 'error' in response:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=response["error"])

    return response['message']


@router.get('/feedback/{user_id}/{book_id}', response_model=FeedbackResponse, status_code=status.HTTP_200_OK)
def get_feedback(user_id: str, book_id: str, fb_model: FeedbackModel = Depends(get_connection)):
    result = fb_model.get_feedback(user_id=user_id, book_id=book_id)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])

    res = FeedbackResponse(user_id=result['UserID'], book_id=result['BookID'],
                           comment=result['Comment'], rating=result['Rating'],
                           time=result['Time'])

    return res
