use actix_web::{App, HttpResponse, HttpServer, Responder, web};
mod db;

// 定义一个简单的路由处理函数
async fn hello() -> impl Responder {
    HttpResponse::Ok().body("Hello Actix Web!")
}

// 定义一个 Echo 路由处理函数
async fn echo(req_body: String) -> impl Responder {
    HttpResponse::Ok().body(req_body)
}

pub async fn run_server() -> std::io::Result<()> {
    db::init_db().await.unwrap();
    HttpServer::new(|| {
        // 直接在闭包中创建 App 实例
        App::new()
            .route("/", web::get().to(hello)) // 添加一个路由
            .route("/echo", web::post().to(echo)) // 添加另一个路由
    })
    .bind("127.0.0.1:8080")? // 使用 ? 操作符处理错误
    .run()
    .await // 运行服务器是异步操作，需要 await
}
