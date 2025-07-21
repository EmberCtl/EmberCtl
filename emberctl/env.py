import os
import secrets

SECRET_KEY = os.environ.get("SECRET_KEY", secrets.token_hex(32))
