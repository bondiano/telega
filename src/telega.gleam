import gleam/result.{try}
import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option, None, Some}
import telega/api
import logging

const telegram_url = "https://api.telegram.org/bot"

type MessageUpdate {
  MessageUpdate(message: Message)
}

pub type Chat {
  Chat(id: Int)
}

pub opaque type Config {
  Config(
    token: String,
    server_url: String,
    webhook_path: String,
    telegram_url: String,
    secret_token: Option(String),
  )
}

pub type Bot {
  Bot(config: Config, handlers: List(Handler))
}

pub type Handler {
  HandleAll(handler: fn(Context) -> Result(Nil, Nil))
}

/// Messages represent the data that the bot receives from the Telegram API.
pub type Message {
  TextMessage(text: String, chat: Chat)
}

pub type Context {
  Context(message: Message, bot: Bot)
}

/// Create a new bot instance.
pub fn new(
  token token: String,
  url server_url: String,
  webhook_path webhook_path: String,
  secret_token secret_token: Option(String),
) -> Bot {
  Bot(
    handlers: [],
    config: Config(
      token: token,
      server_url: server_url,
      webhook_path: webhook_path,
      telegram_url: telegram_url,
      secret_token: secret_token,
    ),
  )
}

/// Set the webhook URL for the bot.
pub fn set_webhook(bot: Bot) -> Result(Bool, String) {
  let webhook_url = bot.config.server_url <> "/" <> bot.config.webhook_path
  use response <- try(api.set_webhook(
    webhook_url: webhook_url,
    token: bot.config.token,
    telegram_url: bot.config.telegram_url,
    secret_token: bot.config.secret_token,
  ))

  case response.status {
    200 -> Ok(True)
    _ -> Error("Failed to set webhook")
  }
}

/// Check if a path is the webhook path for the bot.
pub fn is_webhook_path(bot: Bot, path: String) -> Bool {
  bot.config.webhook_path == path
}

/// Check if a token is the secret token for the bot.
pub fn is_secret_token_valid(bot: Bot, token: String) -> Bool {
  case bot.config.secret_token {
    Some(secret) -> secret == token
    None -> True
  }
}

/// Replies to user with a text message.
pub fn reply(ctx: Context, text: String) -> Result(Nil, Nil) {
  api.send_text(
    token: ctx.bot.config.token,
    telegram_url: ctx.bot.config.telegram_url,
    chat_id: ctx.message.chat.id,
    text: text,
  )
  |> result.map(fn(_) { Nil })
  |> result.nil_error
}

/// Add a handler to the bot.
pub fn add_handler(bot: Bot, handler: Handler) -> Bot {
  Bot(..bot, handlers: [handler, ..bot.handlers])
}

/// Handle an update from the Telegram API.
pub fn handle_update(bot: Bot, message: Message) -> Nil {
  do_handle_update(bot, message, bot.handlers)
}

/// Decode a message from the Telegram API.
pub fn decode_message(json: Dynamic) -> Result(Message, dynamic.DecodeErrors) {
  let decode = build_message_decoder()
  use message_update <- try(decode(json))
  Ok(message_update.message)
}

fn new_context(bot: Bot, message: Message) -> Context {
  Context(message: message, bot: bot)
}

fn build_message_decoder() {
  dynamic.decode1(
    MessageUpdate,
    dynamic.field(
      "message",
      dynamic.decode2(
        TextMessage,
        dynamic.field("text", dynamic.string),
        dynamic.field(
          "chat",
          dynamic.decode1(Chat, dynamic.field("id", dynamic.int)),
        ),
      ),
    ),
  )
}

fn do_handle_update(bot: Bot, message: Message, handlers: List(Handler)) -> Nil {
  case handlers {
    [handler, ..rest] -> {
      case handler.handler(new_context(bot, message)) {
        Ok(_) -> do_handle_update(bot, message, rest)
        Error(_) -> {
          logging.log(logging.Error, "Failed to handle message")
          Nil
        }
      }
    }
    _ -> Nil
  }
}
