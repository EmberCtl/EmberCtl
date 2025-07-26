from fastapi import APIRouter
from emberctl.models.user import UserLoginRequest

router = APIRouter()


@router.post("/login")
async def login(info: UserLoginRequest):
    return "ok"
