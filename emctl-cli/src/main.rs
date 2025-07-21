mod args;
use clap::Parser;
use emctl_core;

#[actix_web::main]
async fn main() {
    let cli = args::Args::parse();
    match cli.cmd {
        args::Command::Serve => {
            let _ = emctl_core::run_server().await;
        }
        _ => {
            println!("Unknown command: {:?}", cli.cmd);
        }
    }
}
