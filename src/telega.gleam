import gleam/list
import gleam/string
import gleam/result
import gleam/function
import gleam/bool
import gleam/otp/actor
import gleam/otp/supervisor
import gleam/erlang/process.{type Subject}
import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import telega/message.{type Message, CommandMessage, TextMessage}
import telega/bot.{type Bot, type Context, Context}
import telega/api
import telega/log

pub opaque type Telega(session) {
  Telega(
    template: Bot,
    handlers: List(Handler(session)),
    session_settings: Option(SessionSettings(session)),
    registry_subject: Option(Subject(RegistryMessage)),
  )
}

pub opaque type SessionSettings(session) {
  SessionSettings(
    persist_session: fn(session) -> String,
    get_session: fn(String) -> Result(session, String),
    get_session_key: fn(Message) -> String,
  )
}

pub type Command {
  Command(
    text: String,
    command: String,
    /// The command arguments, if any.
    payload: Option(String),
  )
}

/// Check if a path is the webhook path for the bot.
pub fn is_webhook_path(telega: Telega(session), path: String) -> Bool {
  bot.get_webhook_path(telega.template) == path
}

/// Check if a secret token is valid.
pub fn is_secret_token_valid(telega: Telega(session), token: String) -> Bool {
  bot.get_secret_token(telega.template) == token
}

pub opaque type Handler(session) {
  /// Handle all messages.
  HandleAll(handler: fn(Context(session)) -> Result(session, String))
  /// Handle a specific command.
  HandleCommand(
    command: String,
    handler: fn(Context(session), Command) -> Result(session, String),
  )
  /// Handle multiple commands.
  HandleCommands(
    commands: List(String),
    handler: fn(Context(session), Command) -> Result(session, String),
  )
  /// Handle text messages.
  HandleText(handler: fn(Context(session), String) -> Result(session, String))
}

pub fn handle_all(
  telega: Telega(session),
  handler: fn(Context(session)) -> Result(session, String),
) -> Telega(session) {
  Telega(..telega, handlers: [HandleAll(handler), ..telega.handlers])
}

pub fn handle_command(
  telega: Telega(session),
  command: String,
  handler: fn(Context(session), Command) -> Result(session, String),
) -> Telega(session) {
  Telega(
    ..telega,
    handlers: [HandleCommand(command, handler), ..telega.handlers],
  )
}

pub fn handle_commands(
  telega: Telega(session),
  commands: List(String),
  handler: fn(Context(session), Command) -> Result(session, String),
) -> Telega(session) {
  Telega(
    ..telega,
    handlers: [HandleCommands(commands, handler), ..telega.handlers],
  )
}

pub fn handle_text(
  telega: Telega(session),
  handler: fn(Context(session), String) -> Result(session, String),
) -> Telega(session) {
  Telega(..telega, handlers: [HandleText(handler), ..telega.handlers])
}

/// Log the message and error message if the handler fails.
pub fn log_context(
  ctx: Context(session),
  prefix: String,
  handler: fn() -> Result(session, String),
) -> Result(session, String) {
  let prefix = "[" <> prefix <> "] "

  log.info(prefix <> "Received message: " <> string.inspect(ctx.message.raw))

  handler()
  |> result.map_error(fn(e) {
    log.error(prefix <> "failed: " <> string.inspect(e))
    e
  })
}

pub fn new(
  token token: String,
  url server_url: String,
  webhook_path webhook_path: String,
  secret_token secret_token: Option(String),
) -> Telega(session) {
  Telega(
    handlers: [],
    template: bot.new(
      token: token,
      url: server_url,
      webhook_path: webhook_path,
      secret_token: secret_token,
    ),
    registry_subject: None,
    session_settings: None,
  )
}

fn nil_session_settings(telega: Telega(Nil)) -> Telega(Nil) {
  Telega(
    ..telega,
    session_settings: Some(
      SessionSettings(
        persist_session: fn(_) { "" },
        get_session: fn(_) { Ok(Nil) },
        get_session_key: fn(_) { "" },
      ),
    ),
  )
}

pub fn init_nil_session(telega: Telega(Nil)) -> Result(Telega(Nil), String) {
  telega
  |> nil_session_settings
  |> init
}

pub fn init(telega: Telega(session)) -> Result(Telega(session), String) {
  use is_ok <- result.try(api.set_webhook(telega.template))
  use <- bool.guard(!is_ok, Error("Failed to set webhook"))

  let session_settings =
    option.to_result(
      telega.session_settings,
      "Session settings not initialized",
    )

  use session_settings <- result.try(session_settings)

  let telega_subject = process.new_subject()
  let registry_actor =
    supervisor.worker(fn(_) {
      start_registry(telega, session_settings, telega_subject)
    })

  use _supervisor_subject <- result.try(
    supervisor.start(supervisor.add(_, registry_actor))
    |> result.map_error(fn(e) {
      "Failed to start telega:\n" <> string.inspect(e)
    }),
  )
  use registry_subject <- result.try(
    process.receive(telega_subject, 1000)
    |> result.map_error(fn(e) {
      "Failed to start registry:\n" <> string.inspect(e)
    }),
  )

  Ok(Telega(..telega, registry_subject: Some(registry_subject)))
}

/// Handle an update from the Telegram API.
pub fn handle_update(
  telega: Telega(session),
  message: Message,
) -> Result(Nil, String) {
  let registry_subject =
    option.to_result(telega.registry_subject, "Registry not initialized")
  use registry_subject <- result.try(registry_subject)

  Ok(actor.send(registry_subject, HandleBotRegistryMessage(message: message)))
}

// Internal Registry stuff --------------------------------------------

type Registry(session) {
  /// Registry works as routing for chat_id to bot instance.
  /// If no bot instance in registry, it will create a new one.
  Registry(
    bots: Dict(Int, Subject(BotInstanseMessage)),
    template: Bot,
    session_settings: SessionSettings(session),
    handlers: List(Handler(session)),
  )
}

type RegistryMessage {
  HandleBotRegistryMessage(message: Message)
}

type BotInstanseMessage {
  HandleBotInstanseMessage(message: Message)
}

type BotInstanse(session) {
  // TODO: add active handler for conversation
  BotInstanse(
    template: Bot,
    chat_id: Int,
    session: session,
    handlers: List(Handler(session)),
  )
}

fn start_registry(
  telega: Telega(session),
  session_settings: SessionSettings(session),
  parent_subject: Subject(Subject(RegistryMessage)),
) -> Result(Subject(RegistryMessage), actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let registry_subject = process.new_subject()
      process.send(parent_subject, registry_subject)

      let selector =
        process.new_selector()
        |> process.selecting(registry_subject, function.identity)

      Registry(
        bots: dict.new(),
        template: telega.template,
        session_settings: session_settings,
        handlers: telega.handlers,
      )
      |> actor.Ready(selector)
    },
    loop: handle_registry_message,
    init_timeout: 1000,
  ))
}

fn handle_registry_message(
  message: RegistryMessage,
  registry: Registry(session),
) {
  case message {
    HandleBotRegistryMessage(message) -> {
      let chat_id = message.raw.chat.id
      case dict.get(registry.bots, chat_id) {
        Ok(bot_subject) -> {
          actor.send(bot_subject, HandleBotInstanseMessage(message))
          actor.continue(registry)
        }
        Error(Nil) -> {
          case init_session(registry.session_settings, message) {
            Ok(session) -> {
              case start_bot_instanse(registry, session, chat_id) {
                Ok(bot_subject) -> {
                  actor.send(bot_subject, HandleBotInstanseMessage(message))
                  actor.continue(
                    Registry(
                      ..registry,
                      bots: dict.insert(registry.bots, chat_id, bot_subject),
                    ),
                  )
                }
                Error(e) -> {
                  log.error(
                    "Failed to start bot instanse:\n" <> string.inspect(e),
                  )
                  actor.continue(registry)
                }
              }
            }
            Error(e) -> {
              log.error("Failed to init session:\n" <> e)
              actor.continue(registry)
            }
          }
        }
      }
    }
  }
}

fn init_session(
  session_settings: SessionSettings(session),
  message: Message,
) -> Result(session, String) {
  session_settings.get_session_key(message)
  |> session_settings.get_session
  |> result.map_error(fn(e) { "Failed to get session:\n " <> string.inspect(e) })
}

fn start_bot_instanse(
  registry: Registry(session),
  session: session,
  chat_id: Int,
) -> Result(Subject(BotInstanseMessage), actor.StartError) {
  BotInstanse(
    template: registry.template,
    chat_id: chat_id,
    session: session,
    handlers: registry.handlers,
  )
  |> actor.start(handle_bot_instanse_message)
}

fn handle_bot_instanse_message(
  message: BotInstanseMessage,
  bot: BotInstanse(session),
) {
  case message {
    HandleBotInstanseMessage(message) -> {
      case do_bot_handle_update(bot, message, bot.handlers) {
        Ok(new_session) -> {
          actor.continue(BotInstanse(..bot, session: new_session))
        }
        Error(e) -> {
          log.error("Failed to handle update:\n" <> e)
          actor.Stop(process.Normal)
        }
      }
    }
  }
}

fn do_bot_handle_update(
  bot: BotInstanse(session),
  message: Message,
  handlers: List(Handler(session)),
) -> Result(session, String) {
  case handlers {
    [handler, ..rest] -> {
      let handle_result = case handler, message.kind {
        HandleAll(handle), _ ->
          handle(Context(
            bot: bot.template,
            message: message,
            session: bot.session,
          ))
        HandleText(handle), TextMessage ->
          handle(
            Context(bot: bot.template, message: message, session: bot.session),
            option.unwrap(message.raw.text, ""),
          )

        HandleCommand(command, handle), CommandMessage -> {
          let message_command = extract_command(message)
          case message_command.command == command {
            True ->
              handle(
                Context(
                  bot: bot.template,
                  message: message,
                  session: bot.session,
                ),
                message_command,
              )
            False -> Error("Command " <> command <> " not found")
          }
        }
        HandleCommands(commands, handle), CommandMessage -> {
          let message_command = extract_command(message)
          case list.contains(commands, message_command.command) {
            True ->
              handle(
                Context(
                  bot: bot.template,
                  message: message,
                  session: bot.session,
                ),
                message_command,
              )
            False ->
              Error(
                "No one command from: "
                <> string.join(commands, ", ")
                <> " found",
              )
          }
        }
        _, _ -> Ok(bot.session)
      }

      case handle_result {
        Ok(_) -> do_bot_handle_update(bot, message, rest)
        Error(e) -> {
          Error(
            "Failed to handle message: \n"
            <> string.inspect(message)
            <> "\n"
            <> e,
          )
        }
      }
    }
    [] -> Ok(bot.session)
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
        [] -> Command(text: text, command: "", payload: None)
      }
    }
  }
}
