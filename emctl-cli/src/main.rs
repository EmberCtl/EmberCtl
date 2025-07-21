mod args;
use clap::Parser;
use emctl_core;

fn main() {
    let cli = args::Args::parse();
    match cli.cmd {
        _ => {
            println!("Unknown command: {:?}", cli.cmd);
        }
    }
}
