from fastapi import HTTPException, status, Depends, APIRouter, Query
from database.database import db_config
from models.book import BookModel, Categories
from schemas.book_schema import BookCreate, BookResponse, BookUpdate
from pydantic import BaseModel
from typing import List


def get_connection():
    return BookModel(db_config=db_config)


router = APIRouter()


@router.post('/book/', status_code=status.HTTP_201_CREATED)
def create_book(book_create: BookCreate, choices: List[Categories] = Query(
    ...,
    description="Select between 1 to 3 valid categories",
    min_items=1,
    max_items=3,
), book_model: BookModel = Depends(get_connection)):
    categories = [choice for choice in choices]
    response = book_model.create_book(book_create.title, book_create.author,
                                      book_create.publication_date, book_create.release_date, categories)

    if 'error' in response:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=response["error"])

    return response


@router.put('/book/{book_id}', status_code=status.HTTP_200_OK)
def update_book(book_id: str, book_update: BookUpdate, book_model: BookModel = Depends(get_connection)):
    result = book_model.update_book_by_id(book_id=book_id, title=book_update.title,
                                          author=book_update.author, publication_date=book_update.publication_date,
                                          rating=book_update.rating, release_date=book_update.release_date)

    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])

    return result['message']


@router.get('/books/{category}', response_model=list[BookResponse], status_code=status.HTTP_200_OK)
def get_book_by_cat(category: str, book_model: BookModel = Depends(get_connection)):
    book_list = book_model.get_book_by_cat(category)
    res = []
    if 'error' in book_list:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=book_list["error"])

    for result in book_list:
        book = BookResponse(bookid=result['BookID'], title=result['Title'],
                            publication_date=result['PublicationDate'],
                            rating=result['Rating'], release_date=result['ReleaseDate'])
        res.append(book)

    return res


@router.get('/book/{book_id}', status_code=status.HTTP_200_OK)
def get_book_by_id(book_id: str, book_model: BookModel = Depends(get_connection)):
    result = book_model.get_book_by_id(book_id=book_id)
    if 'error' in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])
    '''
    res = BookResponse(bookid=result['BookID'], title=result['Title'],
                       publication_date=result['PublicationDate'],
                       rating=result['Rating'], release_date=result['ReleaseDate'])
                       '''
    return result


@router.get('/books/', status_code=status.HTTP_200_OK)
def get_book_list(book_model: BookModel = Depends(get_connection)):
    book_list = book_model.get_book_list()
    res = []
    if 'error' in book_list:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=book_list["error"])

    else:
        for result in book_list:
            book = BookResponse(bookid=result['BookID'], title=result['Title'],
                                publication_date=result['PublicationDate'],
                                rating=result['Rating'], release_date=result['ReleaseDate'])
            res.append(book)

    return res


@router.delete('/book/{book_id}', status_code=status.HTTP_200_OK)
def delete_book_by_id(book_id: str, book_model: BookModel = Depends(get_connection)):
    result = book_model.delete_book(book_id=book_id)
    if "error" in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"])
    return result['message']


'''
@router.get("/select/")
async def select_choice(choice: Choices = Query(..., description="Select a valid option")):
    return {"selected_choice": choice}
    '''
