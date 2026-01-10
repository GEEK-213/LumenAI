# from fastapi import FastAPI
# from pydantic import BaseModel

# app = FastAPI()

# class UserCreate(BaseModel):
#     name: str
#     email: str
#     password: str

# @app.post('/signup')
# def signup_user(user: UserCreate):
#     #request data
#     print(user.name)
#     print(user.email)
#     print(user.password)
#     pass


from fastapi import FastAPI
from models.base import Base
from routes import auth, song
from database import engine

app = FastAPI()

app.include_router(auth.router, prefix='/auth')
app.include_router(song.router, prefix='/song')

Base.metadata.create_all(engine)