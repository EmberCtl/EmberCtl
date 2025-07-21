from tortoise.models import Model
from tortoise import fields
import orjson


class StrJSONField(fields.TextField):  # 将 CharField 改为 TextField
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def to_python_value(self, value):
        try:
            return orjson.loads(value)  # 尝试解析为 JSON
        except orjson.JSONDecodeError:
            return value

    def to_db_value(self, value, instance):
        # 如果值是字典或列表，转换为 JSON 字符串；否则直接存储
        v = orjson.dumps(value)
        if isinstance(v, bytes):
            return v.decode("utf-8")
        else:
            return v


class User(Model):
    name = fields.CharField(max_length=255, pk=True, unique=True, index=True)
    password = fields.CharField(max_length=255)


class Website(Model):
    id = fields.IntField(pk=True)
    name = fields.CharField(max_length=255)
    domains = fields.JSONField()
    type = fields.CharField(max_length=16)


class OperationLog(Model):
    id = fields.IntField(pk=True)
    user = fields.CharField(max_length=255)  # 操作用户
    time = fields.DatetimeField(auto_now_add=True)  # 操作时间
    module = fields.CharField(max_length=255)  # 操作模块
    ip = fields.CharField(max_length=255)  # 操作ip
    ua = fields.TextField()  # 操作ua
    action = fields.CharField(max_length=255)  # 操作动作
    detail = fields.TextField()  # 操作详情


class Config(Model):
    key = fields.CharField(max_length=255, pk=True, unique=True, index=True)
    value = StrJSONField()
