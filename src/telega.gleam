import gleam/result.{try}
import gleam/option.{type Option, None, Some}
import gleam/list
import gleam/string
import telega/message.{type Message, CommandMessage, TextMessage}
import telega/api.{type BotCommands, type BotCommandsOptions}
import telega/log

const telegram_url = "https://api.telegram.org/bot"

pub opaque type Config {
  Config(
    token: String,
    server_url: String,
    webhook_path: String,
    /// An optional string to compare to X-Telegram-Bot-Api-Secret-Token
    secret_token: Option(String),
    telegram_url: String,
  )
}

pub type Bot {
  Bot(config: Config, handlers: List(Handler))
}

pub type Handler {
  /// Handle all messages.
  HandleAll(handler: fn(Context) -> Result(Nil, Nil))
  /// Handle a specific command.
  HandleCommand(
    handler: fn(CommandContext) -> Result(Nil, Nil),
    command: String,
  )
  /// Handle multiple commands.
  HandleCommands(
    handler: fn(CommandContext) -> Result(Nil, Nil),
    commands: List(String),
  )
  /// Handle text messages.
  HandleText(handler: fn(Context) -> Result(Nil, Nil))
}

/// Handlers context.
pub type Context {
  Context(message: Message, bot: Bot)
}

pub type Command {
  Command(
    text: String,
    command: String,
    /// The command arguments, if any.
    payload: Option(String),
  )
}

pub type CommandContext {
  CommandContext(ctx: Context, command: Command)
}

/// Creates a new Bot with the given options.
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

/// Set the webhook URL using [setWebhook](https://core.telegram.org/bots/api#setwebhook) API.
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

/// Use this method to send text messages.
pub fn reply(ctx ctx: Context, text text: String) -> Result(Message, Nil) {
  let chat_id = ctx.message.raw.chat.id

  api.send_message(
    token: ctx.bot.config.token,
    telegram_url: ctx.bot.config.telegram_url,
    chat_id: chat_id,
    text: text,
  )
  |> result.map(fn(_) { ctx.message })
  |> result.nil_error
}

/// Use this method to change the list of the bot's commands. See [commands documentation](https://core.telegram.org/bots/features#commands) for more details about bot commands. Returns True on success.
pub fn set_my_commands(
  ctx ctx: Context,
  commands commands: BotCommands,
  options options: Option(BotCommandsOptions),
) -> Result(Bool, Nil) {
  api.set_my_commands(
    token: ctx.bot.config.token,
    telegram_url: ctx.bot.config.telegram_url,
    commands: commands,
    options: options,
  )
  |> result.map(fn(_) { True })
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

fn do_handle_update(bot: Bot, message: Message, handlers: List(Handler)) -> Nil {
  case handlers {
    [handler, ..rest] -> {
      let handle_result = case handler, message.kind {
        HandleAll(handle), _ -> handle(Context(bot: bot, message: message))
        HandleText(handle), TextMessage ->
          handle(Context(bot: bot, message: message))

        HandleCommand(handle, command), CommandMessage -> {
          let message_command = extract_command(message)
          case message_command.command == command {
            True ->
              handle(CommandContext(
                ctx: Context(bot: bot, message: message),
                command: message_command,
              ))
            False -> Ok(Nil)
          }
        }
        HandleCommands(handle, commands), CommandMessage -> {
          let message_command = extract_command(message)
          case list.contains(commands, message_command.command) {
            True ->
              handle(CommandContext(
                ctx: Context(bot: bot, message: message),
                command: message_command,
              ))
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
