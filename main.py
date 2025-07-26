import click
import uvicorn
import multiprocessing
import emberctl.db
import asyncio
from loguru import logger


@click.group()
def cli():
    logger.info("Starting emberctl")
    pass


@cli.command()
@click.option(
    "-d", "--dev", is_flag=True, help="Run in development mode", default=False
)
def serve(dev):
    args = {"host": "0.0.0.0", "port": 8000, "workers": 1}
    logger.info("Welcoming to EmberCtl server control panel")
    uvicorn.run("emberctl.app:app", **args)


@cli.command()
def init():
    asyncio.run(emberctl.db.init_db())


if __name__ == "__main__":
    cli()
