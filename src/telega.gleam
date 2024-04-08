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

pub opaque type TelegaBuilder(session) {
  TelegaBuilder(telega: Telega(session))
}

pub opaque type SessionSettings(session) {
  SessionSettings(
    // Calls after all handlers to persist the session.
    persist_session: fn(String, session) -> Result(session, String),
    // Calls on initialization of the bot instanse to get the session.
    get_session: fn(String) -> Result(session, String),
    // Constructs the session key from the message.
    // Often it's the chat ID. In case you send group message also include the group ID.
    get_session_key: fn(Message) -> String,
  )
}

pub type Command {
  Command(
    /// Whole command message
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

pub fn new(
  token token: String,
  url server_url: String,
  webhook_path webhook_path: String,
  secret_token secret_token: Option(String),
) -> TelegaBuilder(session) {
  TelegaBuilder(Telega(
    handlers: [],
    template: bot.new(
      token: token,
      url: server_url,
      webhook_path: webhook_path,
      secret_token: secret_token,
    ),
    registry_subject: None,
    session_settings: None,
  ))
}

pub fn handle_all(
  builder: TelegaBuilder(session),
  handler: fn(Context(session)) -> Result(session, String),
) -> TelegaBuilder(session) {
  TelegaBuilder(
    Telega(
      ..builder.telega,
      handlers: [HandleAll(handler), ..builder.telega.handlers],
    ),
  )
}

pub fn handle_command(
  builder: TelegaBuilder(session),
  command: String,
  handler: fn(Context(session), Command) -> Result(session, String),
) -> TelegaBuilder(session) {
  TelegaBuilder(
    Telega(
      ..builder.telega,
      handlers: [HandleCommand(command, handler), ..builder.telega.handlers],
    ),
  )
}

pub fn handle_commands(
  builder: TelegaBuilder(session),
  commands: List(String),
  handler: fn(Context(session), Command) -> Result(session, String),
) -> TelegaBuilder(session) {
  TelegaBuilder(
    Telega(
      ..builder.telega,
      handlers: [HandleCommands(commands, handler), ..builder.telega.handlers],
    ),
  )
}

pub fn handle_text(
  builder: TelegaBuilder(session),
  handler: fn(Context(session), String) -> Result(session, String),
) -> TelegaBuilder(session) {
  TelegaBuilder(
    Telega(
      ..builder.telega,
      handlers: [HandleText(handler), ..builder.telega.handlers],
    ),
  )
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
    log.error(prefix <> "Handler failed: " <> string.inspect(e))
    e
  })
}

pub fn with_session_settings(
  builder: TelegaBuilder(session),
  persist_session persist_session: fn(String, session) ->
    Result(session, String),
  get_session get_session: fn(String) -> Result(session, String),
  get_session_key get_session_key: fn(Message) -> String,
) -> TelegaBuilder(session) {
  TelegaBuilder(
    Telega(
      ..builder.telega,
      session_settings: Some(SessionSettings(
        persist_session: persist_session,
        get_session: get_session,
        get_session_key: get_session_key,
      )),
    ),
  )
}

fn nil_session_settings(builder: TelegaBuilder(Nil)) -> TelegaBuilder(Nil) {
  TelegaBuilder(
    Telega(
      ..builder.telega,
      session_settings: Some(
        SessionSettings(
          persist_session: fn(_, _) { Ok(Nil) },
          get_session: fn(_) { Ok(Nil) },
          get_session_key: fn(_) { "" },
        ),
      ),
    ),
  )
}

pub fn init_nil_session(
  builder: TelegaBuilder(Nil),
) -> Result(Telega(Nil), String) {
  builder
  |> nil_session_settings
  |> init
}

pub fn init(builder: TelegaBuilder(session)) -> Result(Telega(session), String) {
  let TelegaBuilder(telega) = builder
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
    supervisor.supervisor(fn(_) {
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

type RegistryItem {
  RegistryItem(
    bot_subject: Subject(BotInstanseMessage),
    parent_subject: Subject(Subject(BotInstanseMessage)),
  )
}

type Registry(session) {
  /// Registry works as routing for chat_id to bot instance.
  /// If no bot instance in registry, it will create a new one.
  Registry(
    bots: Dict(String, RegistryItem),
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
    key: String,
    session: session,
    template: Bot,
    handlers: List(Handler(session)),
    session_settings: SessionSettings(session),
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
    init_timeout: 10_000,
  ))
}

fn try_send_message(registry_item: RegistryItem, message: Message) {
  process.try_call(
    registry_item.bot_subject,
    fn(_) { HandleBotInstanseMessage(message) },
    1000,
  )
}

fn handle_registry_message(
  message: RegistryMessage,
  registry: Registry(session),
) {
  case message {
    HandleBotRegistryMessage(message) -> {
      let session_key = registry.session_settings.get_session_key(message)

      case dict.get(registry.bots, session_key) {
        Ok(registry_item) -> {
          case try_send_message(registry_item, message) {
            Ok(_) -> actor.continue(registry)
            Error(_) -> add_bot_instance(registry, session_key, message)
          }
        }
        Error(Nil) -> add_bot_instance(registry, session_key, message)
      }
    }
  }
}

fn add_bot_instance(
  registry: Registry(session),
  session_key: String,
  message: Message,
) {
  let parent_subject = process.new_subject()
  let registry_actor =
    supervisor.supervisor(fn(_) {
      start_bot_instanse(
        registry: registry,
        message: message,
        session_key: session_key,
        parent_subject: parent_subject,
      )
    })

  let assert Ok(_supervisor_subject) =
    supervisor.start(supervisor.add(_, registry_actor))

  let bot_subject_result =
    process.receive(parent_subject, 1000)
    |> result.map_error(fn(e) {
      "Failed to start bot instanse:\n" <> string.inspect(e)
    })

  case bot_subject_result {
    Ok(bot_subject) -> {
      let registry_item = RegistryItem(bot_subject, parent_subject)

      case try_send_message(registry_item, message) {
        Ok(_) ->
          actor.continue(
            Registry(
              ..registry,
              bots: dict.insert(registry.bots, session_key, registry_item),
            ),
          )
        Error(_) -> actor.continue(registry)
      }
    }
    Error(e) -> {
      log.error(e)
      actor.continue(registry)
    }
  }
}

fn get_session(
  session_settings: SessionSettings(session),
  message: Message,
) -> Result(session, String) {
  session_settings.get_session_key(message)
  |> session_settings.get_session
  |> result.map_error(fn(e) { "Failed to get session:\n " <> string.inspect(e) })
}

fn start_bot_instanse(
  registry registry: Registry(session),
  message message: Message,
  session_key session_key: String,
  parent_subject parent_subject: Subject(Subject(BotInstanseMessage)),
) -> Result(Subject(BotInstanseMessage), actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let registry_subject = process.new_subject()
      process.send(parent_subject, registry_subject)

      let selector =
        process.new_selector()
        |> process.selecting(registry_subject, function.identity)

      case get_session(registry.session_settings, message) {
        Ok(session) ->
          BotInstanse(
            key: session_key,
            session: session,
            template: registry.template,
            handlers: registry.handlers,
            session_settings: registry.session_settings,
          )
          |> actor.Ready(selector)
        Error(e) -> actor.Failed("Failed to init session:\n" <> e)
      }
    },
    loop: handle_bot_instanse_message,
    init_timeout: 10_000,
  ))
}

fn handle_bot_instanse_message(
  message: BotInstanseMessage,
  bot: BotInstanse(session),
) {
  case message {
    HandleBotInstanseMessage(message) -> {
      case do_bot_handle_update(bot, message, bot.handlers) {
        Ok(new_session) ->
          actor.continue(BotInstanse(..bot, session: new_session))
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
            False -> Ok(bot.session)
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
            False -> Ok(bot.session)
          }
        }
        _, _ -> Ok(bot.session)
      }

      case handle_result {
        Ok(new_session) ->
          do_bot_handle_update(
            BotInstanse(..bot, session: new_session),
            message,
            rest,
          )
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
    [] -> bot.session_settings.persist_session(bot.key, bot.session)
  }
}

fn extract_command(message: Message) -> Command {
  case message.raw.text {
    None -> Command(text: "", command: "", payload: None)
    Some(text) ->
      case string.split(text, " ") {
        [command, ..payload] ->
          Command(text: text, command: command, payload: case payload {
            [] -> None
            [payload, ..] -> Some(payload)
          })
        [] -> Command(text: text, command: "", payload: None)
      }
  }
}
