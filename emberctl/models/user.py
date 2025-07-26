from pydantic import BaseModel


class UserLoginRequest(BaseModel):
    username: str
    password: str
