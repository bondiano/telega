import gleam/list
import gleam/string
import gleam/int
import telega/log
import gleam/option.{type Option, None, Some}
import telega/message.{type Message, CommandMessage, TextMessage}

pub type Command {
  Command(
    text: String,
    command: String,
    /// The command arguments, if any.
    payload: Option(String),
  )
}

/// Handlers context.
pub type Context {
  Context(message: Message, bot: Bot)
}

pub type Handler {
  /// Handle all messages.
  HandleAll(handler: fn(Context) -> Result(Nil, Nil))
  /// Handle a specific command.
  HandleCommand(
    command: String,
    handler: fn(Context, Command) -> Result(Nil, Nil),
  )
  /// Handle multiple commands.
  HandleCommands(
    commands: List(String),
    handler: fn(Context, Command) -> Result(Nil, Nil),
  )
  /// Handle text messages.
  HandleText(handler: fn(Context, String) -> Result(Nil, Nil))
}

pub type Config {
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
  Bot(config: Config, handlers: List(Handler))
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

  Bot(
    handlers: [],
    config: Config(
      token: token,
      server_url: server_url,
      webhook_path: webhook_path,
      secret_token: secret_token,
      max_retry_attempts: None,
      tg_api_url: None,
    ),
  )
}

/// Check if a path is the webhook path for the bot.
pub fn is_webhook_path(bot: Bot, path: String) -> Bool {
  bot.config.webhook_path == path
}

/// Add a handler to the bot.
pub fn add_handler(bot: Bot, handler: Handler) -> Bot {
  Bot(..bot, handlers: [handler, ..bot.handlers])
}

/// Handle an update from the Telegram API.
pub fn handle_update(bot: Bot, message: Message) -> Nil {
  do_handle_update(bot, message, bot.handlers)
}

fn extract_text(message: Message) -> String {
  option.unwrap(message.raw.text, "")
}

fn do_handle_update(bot: Bot, message: Message, handlers: List(Handler)) -> Nil {
  case handlers {
    [handler, ..rest] -> {
      let handle_result = case handler, message.kind {
        HandleAll(handle), _ -> handle(Context(bot: bot, message: message))
        HandleText(handle), TextMessage ->
          handle(Context(bot: bot, message: message), extract_text(message))

        HandleCommand(command, handle), CommandMessage -> {
          let message_command = extract_command(message)
          case message_command.command == command {
            True -> handle(Context(bot: bot, message: message), message_command)
            False -> Ok(Nil)
          }
        }
        HandleCommands(commands, handle), CommandMessage -> {
          let message_command = extract_command(message)
          case list.contains(commands, message_command.command) {
            True -> handle(Context(bot: bot, message: message), message_command)
            False -> Ok(Nil)
          }
        }
        _, _ -> Ok(Nil)
      }

      case handle_result {
        Ok(_) -> do_handle_update(bot, message, rest)
        Error(_) -> {
          log.error("Failed to handle message")
          Nil
        }
      }
    }
    _ -> Nil
  }
}

fn extract_command(message: Message) -> Command {
  case message.raw.text {
    None -> Command(text: "", command: "", payload: None)
    Some(text) -> {
      case string.split(text, " ") {
        [command, ..payload] -> {
          Command(text: text, command: command, payload: case payload {
            [] -> None
            [payload, ..] -> Some(payload)
          })
        }
        _ -> Command(text: text, command: "", payload: None)
      }
    }
  }
}
