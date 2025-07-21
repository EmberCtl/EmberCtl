from tortoise import Tortoise
from . import env
from .models import *
from loguru import logger


async def init_db():
    await Tortoise.init(
        db_url="sqlite://data/db.sqlite3",
        modules={"models": ["emberctl.models"]},
    )
    await Tortoise.generate_schemas()
    await init_settings()


async def init_settings():
    if await Config.get_or_none(key="init") is None:
        logger.warning("Initializing settings")
        await Config.create(key="init", value=True)
