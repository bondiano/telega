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
import telega/keyboard as telega_keyboard
import telega/model.{EditMessageTextParameters, Stringed} as telega_model
import session.{type LanguageBotSession, English, LanguageBotSession, Russian}
import language_keyboard

type BotContext =
  Context(LanguageBotSession)

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

fn t_welcome_message(language) -> String {
  case language {
    English ->
      "Hello! I'm a Change Language bot. You can change language with /lang or /lang_inline commands."
    Russian ->
      "Привет! Я бот для смены языка. Вы можете сменить язык с помощью команд /lang или /lang_inline."
  }
}

fn t_change_language_message(language) -> String {
  case language {
    English -> "Choose your language"
    Russian -> "Выберите ваш язык"
  }
}

fn t_language_changed_message(language) -> String {
  case language {
    English -> "Language changed to English"
    Russian -> "Язык изменен на русский"
  }
}

fn change_languages_keyboard(
  ctx: BotContext,
  _,
) -> Result(LanguageBotSession, String) {
  use <- telega.log_context(ctx, "lang command")

  let language = ctx.session.lang
  let keyboard = language_keyboard.new_keyboard(language)
  use _ <- result.try(telega_api.reply_with_markup(
    ctx,
    t_change_language_message(language),
    telega_keyboard.build(keyboard),
  ))

  use _, text <- telega.wait_hears(ctx, telega_keyboard.hear(keyboard))
  let language = language_keyboard.option_to_language(text)
  use _ <- result.try(telega_api.reply(
    ctx,
    t_language_changed_message(language),
  ))
  Ok(LanguageBotSession(language))
}

fn handle_inline_change_language(
  ctx: BotContext,
  _,
) -> Result(LanguageBotSession, String) {
  use <- telega.log_context(ctx, "lang_inline command")

  let language = ctx.session.lang
  let callback_data = language_keyboard.build_keyboard_callback_data()
  let keyboard = language_keyboard.new_inline_keyboard(language, callback_data)
  use message <- result.try(telega_api.reply_with_markup(
    ctx,
    t_change_language_message(language),
    telega_keyboard.build_inline(keyboard),
  ))

  use ctx, payload, callback_query_id <- telega.wait_callback_query(
    ctx,
    telega_keyboard.filter_inline_keyboard_query(keyboard),
  )

  let assert Ok(language_callback) =
    telega_keyboard.unpack_callback(payload, callback_data)

  let language = language_callback.data

  use _ <- result.try(telega_api.answer_callback_query(
    ctx,
    telega_model.new_answer_callback_query_parameters(callback_query_id),
  ))

  use _ <- result.try(telega_api.edit_message_text(
    ctx,
    EditMessageTextParameters(
      ..telega_model.default_edit_message_text_parameters(),
      text: t_language_changed_message(language),
      message_id: Some(message.message_id),
      chat_id: Some(Stringed(ctx.key)),
    ),
  ))

  Ok(LanguageBotSession(language))
}

fn start_command_handler(
  ctx: BotContext,
  _,
) -> Result(LanguageBotSession, String) {
  use <- telega.log_context(ctx, "start")

  telega_api.set_my_commands(
    ctx.config,
    telega_model.bot_commands_from([
      #("/lang", "Shows custom keyboard with languages"),
      #("/lang_inline", "Change language inline"),
    ]),
    None,
  )
  |> result.then(fn(_) {
    telega_api.reply(ctx, t_welcome_message(ctx.session.lang))
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
  |> telega.handle_command("lang", change_languages_keyboard)
  |> telega.handle_command("lang_inline", handle_inline_change_language)
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
