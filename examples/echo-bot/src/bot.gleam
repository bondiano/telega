import gleam/erlang/process
import gleam/result.{try}
import gleam/erlang/os
import gleam/bool
import dotenv_gleam
import mist
import wisp.{type Request, type Response}
import telega.{type Bot, type Message}

fn middleware(
  req: Request,
  handle_request: fn(wisp.Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  handle_request(req)
}

fn handle_request(bot: Bot, req: Request) -> Response {
  use req <- middleware(req)
  use <- bool.lazy_guard(telega.is_bot_request(bot, req), fn() {
    telega.bot_handler(bot, req)
  })

  case wisp.path_segments(req) {
    ["helath"] -> wisp.ok()
    _ -> wisp.not_found()
  }
}

fn echo_handler(bot: Bot, message: Message) -> Result(Nil, Nil) {
  telega.reply(bot, message, message.text)
}

fn build_bot() -> Result(Bot, Nil) {
  use bot_token <- try(os.get_env("BOT_TOKEN"))
  use secret_path <- try(os.get_env("SECRET_PATH"))
  use server_url <- try(os.get_env("SERVER_URL"))

  telega.new(token: bot_token, url: server_url, secret: secret_path)
  |> telega.add_handler(echo_handler)
  |> Ok
}

pub fn main() {
  dotenv_gleam.config()
  wisp.configure_logger()

  use bot <- try(build_bot())
  let secret_key_base = wisp.random_string(64)
  use _ <- try(
    wisp.mist_handler(handle_request(bot, _), secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http
    |> result.nil_error,
  )

  use _ <- try(
    telega.set_webhook(bot)
    |> result.nil_error,
  )

  process.sleep_forever()

  Ok(Nil)
}
