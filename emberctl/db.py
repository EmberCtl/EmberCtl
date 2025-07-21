from tortoise import Tortoise


async def init_db():
    await Tortoise.init(
        db_url="sqlite://data/db.sqlite3",
        modules={"models": ["emberctl.models"]},
    )
    await Tortoise.generate_schemas()
