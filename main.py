#
import click
import uvicorn
import multiprocessing


@click.group()
def cli():
    pass


@cli.command()
@click.option(
    "-d", "--dev", is_flag=True, help="Run in development mode", default=False
)
def serve(dev):
    args = {
        "host": "0.0.0.0",
        "port": 8000,
        "reload": dev,
    }
    if not dev:
        args["workers"] = 4
    uvicorn.run("emberctl.app:app", **args)


if __name__ == "__main__":
    cli()
