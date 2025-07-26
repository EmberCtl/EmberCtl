from fastapi import FastAPI
from contextlib import asynccontextmanager
from . import db
from loguru import logger
from .api import login_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    await db.get_db()
    app.include_router(login_router)
    yield
    await db.Tortoise.close_connections()


app = FastAPI(lifespan=lifespan, title="emberctl", version="0.0.1")


@app.get("/")
async def root():
    logger.info("Fake Root")
    return {"message": "Hello, World!"}
