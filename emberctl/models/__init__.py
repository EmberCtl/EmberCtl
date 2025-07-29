from typing import Any, Generic, Mapping, Optional, TypeVar

from fastapi.responses import ORJSONResponse
from pydantic import BaseModel

T = TypeVar("T")


class Response(BaseModel, Generic[T]):
    message: str = "OK"
    data: Optional[T] = None
    status_code: int = 200

    def ret(self, headers: Optional[Mapping[str, str]] = None) -> Any:
        """
        创建一个响应，可选的数据和自定义消息。
        """
        return ORJSONResponse(
            status_code=self.status_code,
            content=self.model_dump(),
            headers=headers,
        )

    @classmethod
    def success(cls, data: Optional[T] = None, message: str = "OK") -> "Response[T]":
        """
        创建一个成功的响应，可选的数据和自定义消息。
        """
        return cls(data=data, message=message).ret()

    @classmethod
    def error(cls, message: str = "Error", status_code: int = 500) -> "Response":
        """
        创建一个错误响应，带有自定义消息和状态码。
        """
        return cls(message=message, status_code=status_code).ret()
