import gleam/option.{type Option, None, Some}
import gleam/list
import gleam/string
import telega/message.{type Message, CommandMessage, TextMessage}
import telega/types/message as raw_message
import telega/types/bot_command.{type BotCommand, type BotCommandOptions}
import telega/api
import telega/log

pub opaque type Config {
  Config(
    token: String,
    server_url: String,
    webhook_path: String,
    /// An optional string to compare to X-Telegram-Bot-Api-Secret-Token
    secret_token: Option(String),
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
  HandleText(handler: fn(TextContext) -> Result(Nil, Nil))
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

/// Command handlers context.
pub type CommandContext {
  CommandContext(ctx: Context, command: Command)
}

pub type TextContext {
  TextContext(ctx: Context, text: String)
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
  api.set_webhook(
    webhook_url: webhook_url,
    token: bot.config.token,
    secret_token: bot.config.secret_token,
  )
}

/// Use this method to send text messages.
pub fn reply(
  ctx ctx: Context,
  text text: String,
) -> Result(raw_message.Message, String) {
  let chat_id = ctx.message.raw.chat.id

  api.send_message(token: ctx.bot.config.token, chat_id: chat_id, text: text)
}

/// Use this method to change the list of the bot's commands. See [commands documentation](https://core.telegram.org/bots/features#commands) for more details about bot commands. Returns True on success.
pub fn set_my_commands(
  ctx ctx: Context,
  commands commands: List(BotCommand),
  options options: Option(BotCommandOptions),
) -> Result(Bool, String) {
  api.set_my_commands(
    token: ctx.bot.config.token,
    commands: commands,
    options: options,
  )
}

/// Use this method to get the current list of the bot's commands for the given scope and user language.
pub fn get_my_commands(
  ctx: Context,
  options options: Option(BotCommandOptions),
) -> Result(List(BotCommand), String) {
  api.get_my_commands(token: ctx.bot.config.token, options: options)
}

/// Use this method to delete the list of the bot's commands for the given scope and user language. After deletion, [higher level commands](https://core.telegram.org/bots/api#determining-list-of-commands) will be shown to affected users.
pub fn delete_my_commands(
  ctx: Context,
  options options: Option(BotCommandOptions),
) -> Result(Bool, String) {
  api.delete_my_commands(token: ctx.bot.config.token, options: options)
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

fn extract_text(message: Message) -> String {
  option.unwrap(message.raw.text, "")
}

fn do_handle_update(bot: Bot, message: Message, handlers: List(Handler)) -> Nil {
  case handlers {
    [handler, ..rest] -> {
      let handle_result = case handler, message.kind {
        HandleAll(handle), _ -> handle(Context(bot: bot, message: message))
        HandleText(handle), TextMessage ->
          handle(TextContext(
            ctx: Context(bot: bot, message: message),
            text: extract_text(message),
          ))

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
