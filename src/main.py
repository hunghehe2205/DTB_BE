from fastapi import FastAPI
from routers.user_route import router as user_router
from routers.membership_route import router as mem_router
from routers.book_route import router as book_router
from routers.transact_route import router as trans_router
from routers.feedback_router import router as fb_router
app = FastAPI()


app.include_router(user_router, tags=["Users"])
app.include_router(mem_router, tags=["Membership"])
app.include_router(book_router, tags=["Book"])
app.include_router(trans_router, tags=['Transaction'])
app.include_router(fb_router, tags=['Feedback'])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)