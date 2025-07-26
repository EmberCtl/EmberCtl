from tortoise import Tortoise
from .models import Config
from .env import logger, DATA_PATH
from threading import Lock
import os
import sys

_lock = Lock()


async def init_settings():
    """
    初始化或更新默认配置
    """
    try:
        with _lock:
            config = await Config.get_or_none(key="init")
            if not config:
                logger.info("Initializing database settings...")
                await Config.create(key="init", value=True)
                # 可以在这里添加更多初始配置
                logger.info("Database settings initialized")
            else:
                logger.info("Using existing database settings")
    except Exception as e:
        logger.error(f"Database settings initialization failed: {e}")
        raise


async def test_connection():
    """
    测试数据库连接和基础表格
    """
    try:
        await Tortoise.get_connection("default").execute_query("SELECT 1")
        if not await Config.get_or_none(key="init"):
            raise ValueError("Database not initialized")
        logger.info("Database connection test successful")
        return True
    except Exception as e:
        await Tortoise.close_connections()
        raise


async def init_db():
    """
    初始化数据库所有组件
    """
    try:
        db_path = os.path.join(DATA_PATH, "db.sqlite3")
        await Tortoise.init(
            db_url=f"sqlite://{db_path}",
            modules={"models": ["emberctl.models"]},
        )
        logger.info("Successfully connected to database")
        await Tortoise.generate_schemas()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        await Tortoise.close_connections()
        raise


async def close_db():
    """
    关闭数据库连接
    """
    try:
        await Tortoise.close_connections()
        logger.info("Database connections closed successfully")
    except Exception as e:
        logger.error(f"Error closing database connections: {e}")
        raise
