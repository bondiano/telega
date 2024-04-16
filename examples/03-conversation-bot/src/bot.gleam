import gleam/result
import gleam/option.{None, Some}
import gleam/erlang/os
import gleam/erlang/process
import dotenv_gleam
import mist
import wisp.{type Response}
import telega
import telega/bot.{type Context}
import telega/adapters/wisp as telega_wisp
import telega/api as telega_api
import telega/model as telega_model
import session.{type NameBotSession, NameBotSession}

type BotContext =
  Context(NameBotSession)

fn middleware(req, bot, handle_request) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use <- telega_wisp.handle_bot(req, bot)
  use req <- wisp.handle_head(req)
  handle_request(req)
}

fn handle_request(bot, req) -> Response {
  use req <- middleware(req, bot)

  case wisp.path_segments(req) {
    ["helath"] -> wisp.ok()
    _ -> wisp.not_found()
  }
}

fn set_name_command_handler(
  ctx: BotContext,
  _,
) -> Result(NameBotSession, String) {
  use <- telega.log_context(ctx, "set_name command")
  use _ <- result.try(telega_api.reply(ctx, "What's your name?"))
  use ctx, name <- telega.wait_text(ctx)
  use _ <- result.try(telega_api.reply(ctx, "Your name is: " <> name <> " set!"))

  Ok(NameBotSession(name: name))
}

fn get_name_command_handler(
  ctx: BotContext,
  _,
) -> Result(NameBotSession, String) {
  use <- telega.log_context(ctx, "get_name command")

  telega_api.reply(ctx, "Your name is: " <> ctx.session.name)
  |> result.map(fn(_) { ctx.session })
}

fn start_command_handler(ctx, _) -> Result(NameBotSession, String) {
  use <- telega.log_context(ctx, "start")

  telega_api.set_my_commands(
    ctx.config,
    telega_model.bot_commands_from([
      #("/set_name", "Set name"),
      #("/get_name", "Get name"),
    ]),
    None,
  )
  |> result.then(fn(_) {
    telega_api.reply(
      ctx,
      "Hello! I'm a Name bot. You can set your name with /set_name command.",
    )
    |> result.map(fn(_) { ctx.session })
  })
}

fn build_bot() {
  let assert Ok(bot_token) = os.get_env("BOT_TOKEN")
  let assert Ok(webhook_path) = os.get_env("WEBHOOK_PATH")
  let assert Ok(server_url) = os.get_env("SERVER_URL")
  let assert Ok(secret_token) = os.get_env("BOT_SECRET_TOKEN")

  telega.new(
    token: bot_token,
    url: server_url,
    webhook_path: webhook_path,
    secret_token: Some(secret_token),
  )
  |> telega.handle_command("start", start_command_handler)
  |> telega.handle_command("set_name", set_name_command_handler)
  |> telega.handle_command("get_name", get_name_command_handler)
  |> session.attach
  |> telega.init
}

pub fn main() {
  dotenv_gleam.config()
  wisp.configure_logger()

  let assert Ok(bot) = build_bot()
  let secret_key_base = wisp.random_string(64)
  let assert Ok(_) =
    wisp.mist_handler(handle_request(bot, _), secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http
    |> result.nil_error

  process.sleep_forever()
  Ok(Nil)
}