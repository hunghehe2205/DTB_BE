from fastapi import FastAPI
from routers.user_route import router as user_router
from routers.membership_route import router as mem_router
from routers.book_route import router as book_router
from routers.transact_route import router as trans_router
from routers.feedback_route import router as fb_router
from routers.access_route import router as access_router
from routers.friends_route import router as friends_router
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    # Replace '*' with the specific origin if needed
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(user_router, tags=["Users"])
app.include_router(mem_router, tags=["Membership"])
app.include_router(book_router, tags=["Book"])
app.include_router(trans_router, tags=['Transaction'])
app.include_router(fb_router, tags=['Feedback'])
app.include_router(access_router, tags=['Access'])
app.include_router(friends_router, tags=['Friend'])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
