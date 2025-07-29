from fastapi import APIRouter
from emberctl.models.user import UserLoginRequest
from emberctl.models import Response
import hashlib
from emberctl.schema import User, OperationLog, LoginToken
import random
from captcha.image import ImageCaptcha
from fastapi.responses import Response as FastAPIResponse
import time
import datetime

router = APIRouter()


captcha_map = {}


@router.post("/login")
async def login(info: UserLoginRequest) -> Response[str]:
    # 登录
    if info.captcha != captcha_map.get(info.username):
        return Response.error("验证码错误")
    u = await User.get_or_none(username=info.username)

    await OperationLog.log(u, "user", "login", f"尝试登录")
    if u is None:
        return Response.error("用户不存在")
    hash_pwd = hashlib.sha256(info.password.encode("utf-8")).hexdigest()
    if u.password != hash_pwd:  # type: ignore
        return Response.error("密码错误")
    await OperationLog.log(u, "user", "login", f"登录成功")  # type: ignore
    token = hashlib.sha256(f"{u.name}{time.time()}".encode("utf-8")).hexdigest()
    await LoginToken.create(
        user=u,
        token=token,
        expire_at=datetime.datetime.now() + datetime.timedelta(hours=3),
    )
    return Response.success("ok")


@router.get("/make_captcha")
async def make_captcha(user: str):
    """
    生成验证码
    """
    captcha = ImageCaptcha()
    chars = random.choices("abcdefghijkmnpqrstwxyzABCDEFGHJKLMNPQRSTWXYZ123456789", k=4)
    img = captcha.generate("".join(chars))
    captcha_map[user] = "".join(chars)
    return FastAPIResponse(img.read())
