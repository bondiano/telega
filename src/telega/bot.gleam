import gleam/int
import gleam/option.{type Option, None}
import telega/message.{type Message}

const telegram_url = "https://api.telegram.org/bot"

const default_retry_count = 3

/// Handlers context.
pub type Context(session) {
  Context(message: Message, bot: Bot, session: session)
}

pub opaque type Config {
  Config(
    token: String,
    server_url: String,
    webhook_path: String,
    /// String to compare to X-Telegram-Bot-Api-Secret-Token
    secret_token: String,
    /// The maximum number of times to retry sending a API message. Default is 3.
    max_retry_attempts: Option(Int),
    /// The Telegram Bot API URL. Default is "https://api.telegram.org".
    /// This is useful for running [a local server](https://core.telegram.org/bots/api#using-a-local-bot-api-server).
    tg_api_url: Option(String),
  )
}

pub type Bot {
  /// Bot constructor. Represents a bot configuration wich will be used to create a Bot instance per chat.
  Bot(config: Config)
}

/// Creates a new Bot with the given options.
///
/// If `secret_token` is not provided, a random one will be generated.
pub fn new(
  token token: String,
  url server_url: String,
  webhook_path webhook_path: String,
  secret_token secret_token: Option(String),
) -> Bot {
  let secret_token =
    option.lazy_unwrap(secret_token, fn() {
      int.random(1_000_000)
      |> int.to_string
    })

  Bot(config: Config(
    token: token,
    server_url: server_url,
    webhook_path: webhook_path,
    secret_token: secret_token,
    max_retry_attempts: None,
    tg_api_url: None,
  ))
}

pub fn get_secret_token(bot: Bot) -> String {
  bot.config.secret_token
}

pub fn get_tg_api_url(bot: Bot) -> String {
  option.unwrap(bot.config.tg_api_url, telegram_url)
}

pub fn get_token(bot: Bot) -> String {
  bot.config.token
}

pub fn get_max_retry_attempts(bot: Bot) -> Int {
  option.unwrap(bot.config.max_retry_attempts, default_retry_count)
}

pub fn get_server_url(bot: Bot) -> String {
  bot.config.server_url
}

pub fn get_webhook_path(bot: Bot) -> String {
  bot.config.webhook_path
}
