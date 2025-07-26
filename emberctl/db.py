from tortoise import Tortoise
from .schema import Config, User, OperationLog, Website
from .env import logger, DATA_PATH
from threading import Lock
import os
import sys
import secrets
import hashlib

dblock = Lock()


async def init_settings():
    """
    初始化或更新默认配置
    """
    try:
        with dblock:
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


async def get_db(test=True):
    try:
        db_path = os.path.join(DATA_PATH, "db.sqlite3")
        await Tortoise.init(
            db_url=f"sqlite://{db_path}",
            modules={"models": ["emberctl.schema"]},
        )
        logger.info("Database connection successful")
        if test:
            await Tortoise.get_connection("default").execute_query("SELECT 1")
            if not await Config.get_or_none(key="init"):
                raise ValueError("Database not initialized")
    except Exception as e:
        logger.error(e)
    finally:
        await Tortoise.close_connections()


async def init_db():
    """
    初始化数据库所有组件
    """
    try:
        await get_db(False)
        try:
            if await Config.get_or_none(key="init"):
                raise ValueError("Database already initialized")
        except Exception:
            pass

        await Tortoise.generate_schemas()
        logger.info("Database initialized successfully")

        password = secrets.token_urlsafe(12)
        admin = User(
            name="admin",
            password=hashlib.sha256(password.encode()).hexdigest(),
        )
        await OperationLog.log(
            "system", "user", "create", f"Created user: {admin.name}"
        )
        print(f"Generated admin password: {password}")
        await admin.save()

        await init_settings()
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        raise
    finally:
        await Tortoise.close_connections()


async def reset_pwd():
    """
    重置管理员密码
    """
    try:
        await get_db()

        # 生成新的随机密码
        new_password = secrets.token_urlsafe(12)
        hashed_password = hashlib.sha256(new_password.encode()).hexdigest()

        # 获取管理员用户并更新密码
        admin = await User.get(name="admin")
        old_password = admin.password
        admin.password = hashed_password
        await admin.save()

        # 记录操作日志
        await OperationLog.log("system", "user", "update", "Reset admin password")

        # 打印新密码
        print(f"New admin password: {new_password}")
        logger.info("Admin password reset successfully")

        # 关闭数据库连接
        await Tortoise.close_connections()

        return new_password
    except Exception as e:
        logger.error(f"Failed to reset admin password: {e}")
        raise
