import click
import uvicorn
import multiprocessing
import emberctl.env
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
    args = {
        "host": "0.0.0.0",
        "port": 8000,
        "workers": 4,
    }
    if not dev:
        args["workers"] = 4
    uvicorn.run("emberctl.app:app", **args)


if __name__ == "__main__":
    cli()
