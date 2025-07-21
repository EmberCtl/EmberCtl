use clap::{Parser, Subcommand};

// 定义根命令
#[derive(Parser, Debug)]
#[clap(name = "emctl", version = env!("CARGO_PKG_VERSION"), about = "A hitokoto server in Rust", long_about = None)]
pub struct Args {
    #[command(subcommand)]
    pub cmd: Command,
}

// 定义顶层子命令枚举
#[derive(Subcommand, Debug)]
pub enum Command {
    Serve,
    /// Stop EmberCtl server
    Stop,
    /// Start EmberCtl server
    Start,
    /// Update EmberCtl information
    Update {
        #[command(subcommand)]
        cmd: UpdateCommand,
    },
    /// Print version
    Version,
    /// Reset some information
    Reset {
        #[command(subcommand)]
        cmd: ResetCommand,
    },
}

// 定义 Update 命令的子命令枚举
#[derive(Subcommand, Debug)]
pub enum UpdateCommand {
    /// Update username
    Username,
    /// Update password
    Password,
    /// Update listening port
    Port,
    /// Update listening host
    Host,
}

#[derive(Subcommand, Debug)]
pub enum ResetCommand {
    Domain,
    Entry,
    IP,
    Htps,
}
