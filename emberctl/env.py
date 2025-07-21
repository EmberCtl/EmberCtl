import os
import secrets
from loguru import logger
import sys

SECRET_KEY = os.environ.get("SECRET_KEY", secrets.token_hex(32))
LOG_DIR = "data/logs"
LOG_FILE = f"{LOG_DIR}/emberctl.log"


os.makedirs(LOG_DIR, exist_ok=True)

logger.remove()

# 文件日志
logger.add(
    LOG_FILE,
    level="TRACE",  # 使用可配置的文件日志级别
    rotation="5 MB",  # 每当日志文件达到5MB时进行轮转
    backtrace=True,  # 显示异常的完整回溯信息
    diagnose=True,  # 诊断变量值，有助于调试
    enqueue=True,
    encoding="utf-8",  # 指定文件编码
)

# 控制台日志
logger.add(
    sys.stdout,
    level="INFO",  # 使用可配置的控制台日志级别
    enqueue=True,  # 使用队列，异步写入日志
    colorize=True,  # 为控制台输出添加颜色，提高可读性
    format="<green>{time:HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{message}</cyan>",
)
