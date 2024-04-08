import gleam/erlang/process
import gleam/result
import gleam/option.{None, Some}
import gleam/erlang/os
import dotenv_gleam
import mist
import wisp.{type Request, type Response}
import telega.{type Telega}
import telega/bot.{type Context}
import telega/adapters/wisp as telega_wisp
import telega/api as telega_api
import telega/model as telega_model

type Bot =
  Telega(Nil)

type NilContext =
  Context(Nil)

fn middleware(
  req: Request,
  bot: Bot,
  handle_request: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use <- telega_wisp.handle_bot(req, bot)
  use req <- wisp.handle_head(req)
  handle_request(req)
}

fn handle_request(bot: Bot, req: Request) -> Response {
  use req <- middleware(req, bot)

  case wisp.path_segments(req) {
    ["helath"] -> wisp.ok()
    _ -> wisp.not_found()
  }
}

fn dice_command_handler(ctx: NilContext, _) -> Result(Nil, String) {
  use <- telega.log_context(ctx, "dice")

  telega_api.send_dice(ctx, None)
  |> result.map(fn(_) { Nil })
}

fn start_command_handler(ctx: NilContext, _) -> Result(Nil, String) {
  use <- telega.log_context(ctx, "start")

  telega_api.set_my_commands(
    ctx,
    telega_model.bot_commands_from([#("/dice", "Roll a dice")]),
    None,
  )
  |> result.then(fn(_) {
    telega_api.reply(
      ctx,
      "Hello! I'm a dice bot. You can roll a dice by sending /dice command.",
    )
    |> result.map(fn(_) { Nil })
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
  |> telega.handle_command("dice", dice_command_handler)
  |> telega.handle_command("start", start_command_handler)
  |> telega.init_nil_session
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
