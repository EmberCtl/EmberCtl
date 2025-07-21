from tortoise.models import Model
from tortoise import fields


class User(Model):
    name = fields.CharField(max_length=255, pk=True)
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
    key = fields.CharField(max_length=255, pk=True)
    value = fields.JSONField()
