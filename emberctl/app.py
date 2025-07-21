from fastapi import FastAPI
from contextlib import asynccontextmanager
from . import db
import os


@asynccontextmanager
async def lifespan(app: FastAPI):
    os.makedirs("data", exist_ok=True)
    await db.init_db()
    yield
    await db.Tortoise.close_connections()


app = FastAPI(lifespan=lifespan, title="emberctl", version="0.0.1")


@app.get("/")
async def root():
    return {"message": "Hello, World!"}
