import gleam/int
import gleam/option.{type Option, None}

const telegram_url = "https://api.telegram.org/bot"

const default_retry_count = 3

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

/// Creates a new Bot with the given options.
///
/// If `secret_token` is not provided, a random one will be generated.
pub fn new(
  token token: String,
  url server_url: String,
  webhook_path webhook_path: String,
  secret_token secret_token: Option(String),
) -> Config {
  let secret_token =
    option.lazy_unwrap(secret_token, fn() {
      int.random(1_000_000)
      |> int.to_string
    })

  Config(
    token: token,
    server_url: server_url,
    webhook_path: webhook_path,
    secret_token: secret_token,
    max_retry_attempts: None,
    tg_api_url: None,
  )
}

pub fn get_secret_token(config: Config) -> String {
  config.secret_token
}

pub fn get_tg_api_url(config: Config) -> String {
  option.unwrap(config.tg_api_url, telegram_url)
}

pub fn get_token(config: Config) -> String {
  config.token
}

pub fn get_max_retry_attempts(config: Config) -> Int {
  option.unwrap(config.max_retry_attempts, default_retry_count)
}

pub fn get_server_url(config: Config) -> String {
  config.server_url
}

pub fn get_webhook_path(config: Config) -> String {
  config.webhook_path
}
