from fastapi import FastAPI
from contextlib import asynccontextmanager
from . import db
from loguru import logger
from .api import auth_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    await db.get_db()
    app.include_router(auth_router)
    yield
    await db.Tortoise.close_connections()


app = FastAPI(lifespan=lifespan, title="emberctl", version="0.0.1", root_path="/sd")


@app.get("/")
async def root():
    logger.info("Fake Root")
    return {"message": "Hello, World!"}
