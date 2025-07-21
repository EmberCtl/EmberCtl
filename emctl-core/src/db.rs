use sqlx::sqlite::{SqlitePool, SqlitePoolOptions};
use sqlx::{Sqlite, migrate::MigrateDatabase};

static DB_URL: &str = "sqlite://emctl.db";

pub async fn init_db() -> Result<SqlitePool, sqlx::Error> {
    if !Sqlite::database_exists(DB_URL).await? {
        Sqlite::create_database(DB_URL).await?;
    }
    let pool = SqlitePoolOptions::new()
        .max_connections(1)
        .connect(DB_URL)
        .await?;
    Ok(pool)
}
