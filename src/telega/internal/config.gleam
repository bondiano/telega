import gleam/int
import gleam/option.{type Option}
import telega/api.{type TelegramApiConfig, TelegramApiConfig}

const telegram_url = "https://api.telegram.org/bot"

const default_retry_count = 3

pub type Config {
  Config(
    server_url: String,
    webhook_path: String,
    /// String to compare to X-Telegram-Bot-Api-Secret-Token
    secret_token: String,
    api: TelegramApiConfig,
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
    server_url: server_url,
    webhook_path: webhook_path,
    secret_token: secret_token,
    api: TelegramApiConfig(
      token,
      max_retry_attempts: default_retry_count,
      tg_api_url: telegram_url,
    ),
  )
}
