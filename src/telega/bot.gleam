import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/otp/supervisor
import gleam/regex.{type Regex}
import gleam/result
import gleam/string
import telega/api
import telega/internal/config.{type Config}
import telega/log
import telega/model
import telega/update.{
  type Command, type Update, CallbackQueryUpdate, CommandUpdate, TextUpdate,
  UnknownUpdate,
}

// Registry --------------------------------------------------------------------

type RegestrySubject =
  Subject(RegistryMessage)

type RootBotInstanseSubject(session) =
  Subject(Subject(BotInstanseMessage(session)))

type Registry(session) {
  /// Registry works as routing for chat_id to bot instance.
  /// If no bot instance in registry, it will create a new one.
  Registry(
    bots: Dict(String, RegistryItem(session)),
    config: Config,
    session_settings: SessionSettings(session),
    handlers: List(Handler(session)),
    registry_subject: RegestrySubject,
    bot_instances_subject: RootBotInstanseSubject(session),
  )
}

type BotInstanseSubject(session) =
  Subject(BotInstanseMessage(session))

type RegistryItem(session) =
  BotInstanseSubject(session)

pub type RegistryMessage {
  HandleBotRegistryMessage(update: Update)
}

fn try_send_update(registry_item: RegistryItem(session), update: Update) {
  process.try_call(registry_item, BotInstanseMessageNew(_, update), 1000)
}

fn handle_registry_message(
  message: RegistryMessage,
  registry: Registry(session),
) {
  case message {
    HandleBotRegistryMessage(message) ->
      case get_session_key(message) {
        Ok(session_key) ->
          case dict.get(registry.bots, session_key) {
            Ok(registry_item) -> {
              case try_send_update(registry_item, message) {
                Ok(_) -> actor.continue(registry)
                Error(_) -> add_bot_instance(registry, session_key, message)
              }
            }
            Error(Nil) -> add_bot_instance(registry, session_key, message)
          }
        Error(e) -> {
          log.error("Failed to get session key: " <> string.inspect(e))
          actor.continue(registry)
        }
      }
  }
}

fn add_bot_instance(
  registry: Registry(session),
  session_key: String,
  update: Update,
) {
  let registry_actor =
    supervisor.supervisor(fn(_) {
      start_bot_instanse(
        registry: registry,
        update: update,
        session_key: session_key,
        parent_subject: registry.bot_instances_subject,
      )
    })

  let assert Ok(_supervisor_subject) =
    supervisor.start(supervisor.add(_, registry_actor))

  let bot_subject_result =
    process.receive(registry.bot_instances_subject, 1000)
    |> result.map_error(fn(e) {
      "Failed to start bot instanse:\n" <> string.inspect(e)
    })

  case bot_subject_result {
    Ok(bot_subject) -> {
      case try_send_update(bot_subject, update) {
        Ok(_) ->
          actor.continue(
            Registry(
              ..registry,
              bots: dict.insert(registry.bots, session_key, bot_subject),
            ),
          )
        Error(e) -> {
          log.error(
            "Failed to send message to bot instanse: " <> string.inspect(e),
          )
          actor.continue(registry)
        }
      }
    }
    Error(e) -> {
      log.error(e)
      actor.continue(registry)
    }
  }
}

/// Set webhook for the bot.
pub fn set_webhook(config config: Config) -> Result(Bool, String) {
  api.set_webhook(
    config.api,
    model.SetWebhookParameters(
      url: config.server_url <> "/" <> config.webhook_path,
      max_connections: None,
      ip_address: None,
      allowed_updates: None,
      drop_pending_updates: None,
      secret_token: Some(config.secret_token),
    ),
  )
}

pub fn start_registry(
  config: Config,
  handlers: List(Handler(session)),
  session_settings: SessionSettings(session),
  root_subject: Subject(RegestrySubject),
) -> Result(RegestrySubject, actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let registry_subject = process.new_subject()
      let bot_instances_subject = process.new_subject()
      process.send(root_subject, registry_subject)

      let selector =
        process.new_selector()
        |> process.selecting(registry_subject, function.identity)

      Registry(
        bots: dict.new(),
        config: config,
        session_settings: session_settings,
        handlers: handlers,
        registry_subject: registry_subject,
        bot_instances_subject: bot_instances_subject,
      )
      |> actor.Ready(selector)
    },
    loop: handle_registry_message,
    init_timeout: 10_000,
  ))
}

pub fn wait_handler(
  ctx: Context(session),
  handler: Handler(session),
) -> Result(session, String) {
  process.send(ctx.bot_subject, BotInstanseMessageWaitHandler(handler))
  Ok(ctx.session)
}

fn new_context(bot: BotInstanse(session), update: Update) -> Context(session) {
  Context(
    update: update,
    key: bot.key,
    config: bot.config,
    session: bot.session,
    bot_subject: bot.own_subject,
  )
}

// Session ---------------------------------------------------------------------

pub type SessionSettings(session) {
  SessionSettings(
    // Calls after all handlers to persist the session.
    persist_session: fn(String, session) -> Result(session, String),
    // Calls on initialization of the bot instanse to get the session.
    get_session: fn(String) -> Result(session, String),
  )
}

fn get_session_key(update: Update) -> Result(String, String) {
  case update {
    CommandUpdate(chat_id: chat_id, ..) -> Ok(int.to_string(chat_id))
    TextUpdate(chat_id: chat_id, ..) -> Ok(int.to_string(chat_id))
    CallbackQueryUpdate(from_id: from_id, ..) -> Ok(int.to_string(from_id))
    UnknownUpdate(..) ->
      Error("Unknown update type don't allow to get session key")
  }
}

fn get_session(
  session_settings: SessionSettings(session),
  update: Update,
) -> Result(session, String) {
  use key <- result.try(get_session_key(update))

  session_settings.get_session(key)
  |> result.map_error(fn(e) { "Failed to get session:\n " <> string.inspect(e) })
}

fn start_bot_instanse(
  registry registry: Registry(session),
  update update: Update,
  session_key session_key: String,
  parent_subject parent_subject: RootBotInstanseSubject(session),
) -> Result(BotInstanseSubject(session), actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let actor_subj = process.new_subject()
      process.send(parent_subject, actor_subj)
      let selector =
        process.new_selector()
        |> process.selecting(actor_subj, function.identity)

      case get_session(registry.session_settings, update) {
        Ok(session) ->
          BotInstanse(
            key: session_key,
            session: session,
            config: registry.config,
            handlers: registry.handlers,
            session_settings: registry.session_settings,
            active_handler: None,
            own_subject: actor_subj,
          )
          |> actor.Ready(selector)
        Error(e) -> actor.Failed("Failed to init bot instanse:\n" <> e)
      }
    },
    loop: handle_bot_instanse_message,
    init_timeout: 10_000,
  ))
}

// Bot Instanse --------------------------------------------------------------------

/// Handlers context.
pub type Context(session) {
  Context(
    key: String,
    update: Update,
    config: Config,
    session: session,
    bot_subject: BotInstanseSubject(session),
  )
}

pub type BotInstanseMessage(session) {
  BotInstanseMessageOk
  BotInstanseMessageNew(client: BotInstanseSubject(session), update: Update)
  BotInstanseMessageWaitHandler(handler: Handler(session))
}

type BotInstanse(session) {
  BotInstanse(
    key: String,
    session: session,
    config: Config,
    handlers: List(Handler(session)),
    session_settings: SessionSettings(session),
    active_handler: Option(Handler(session)),
    own_subject: BotInstanseSubject(session),
  )
}

fn handle_bot_instanse_message(
  message: BotInstanseMessage(session),
  bot: BotInstanse(session),
) {
  case message {
    BotInstanseMessageNew(client, message) -> {
      case bot.active_handler {
        Some(handler) ->
          case do_handle(bot, message, handler) {
            Some(Ok(new_session)) -> {
              actor.send(client, BotInstanseMessageOk)
              actor.continue(
                BotInstanse(..bot, session: new_session, active_handler: None),
              )
            }
            Some(Error(e)) -> {
              log.error("Failed to handle update:\n" <> e)
              actor.Stop(process.Normal)
            }
            None -> {
              actor.send(client, BotInstanseMessageOk)
              actor.continue(bot)
            }
          }
        None ->
          case loop_handlers(bot, message, bot.handlers) {
            Ok(new_session) -> {
              actor.send(client, BotInstanseMessageOk)
              actor.continue(BotInstanse(..bot, session: new_session))
            }
            Error(e) -> {
              log.error("Failed to handle update:\n" <> e)
              actor.Stop(process.Normal)
            }
          }
      }
    }
    BotInstanseMessageWaitHandler(handler) ->
      actor.continue(BotInstanse(..bot, active_handler: Some(handler)))
    BotInstanseMessageOk -> actor.continue(bot)
  }
}

// Hears -----------------------------------------------------------------------

pub type Hears {
  HearText(text: String)
  HearTexts(texts: List(String))
  HearRegex(regex: Regex)
  HearRegexes(regexes: List(Regex))
}

fn hears_check(text: String, hear: Hears) -> Bool {
  case hear {
    HearText(str) -> text == str
    HearTexts(strs) -> list.contains(strs, text)
    HearRegex(re) -> regex.check(re, text)
    HearRegexes(regexes) -> list.any(regexes, regex.check(_, text))
  }
}

pub type Handler(session) {
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
  /// Handle text message with a specific substring.
  HandleHears(
    hears: Hears,
    handler: fn(Context(session), String) -> Result(session, String),
  )
  /// Handle callback query. Context, data from callback query and `callback_query_id` are passed to the handler.
  HandleCallbackQuery(
    filter: CallbackQueryFilter,
    handler: fn(Context(session), String, String) -> Result(session, String),
  )
}

pub type CallbackQueryFilter {
  CallbackQueryFilter(re: Regex)
}

fn do_handle(
  bot: BotInstanse(session),
  update: Update,
  handler: Handler(session),
) -> Option(Result(session, String)) {
  case handler, update {
    HandleAll(handle), _ -> Some(handle(new_context(bot, update)))
    HandleText(handle), TextUpdate(text: text, ..) ->
      Some(handle(new_context(bot, update), text))
    HandleHears(hear, handle), TextUpdate(text: text, ..) -> {
      case hears_check(text, hear) {
        True -> Some(handle(new_context(bot, update), text))
        False -> None
      }
    }
    HandleCommand(command, handle), CommandUpdate(command: update_command, ..) ->
      case update_command.command == command {
        True -> Some(handle(new_context(bot, update), update_command))
        False -> None
      }
    HandleCommands(commands, handle), CommandUpdate(command: update_command, ..)
    -> {
      case list.contains(commands, update_command.command) {
        True -> Some(handle(new_context(bot, update), update_command))
        False -> None
      }
    }
    HandleCallbackQuery(filter, handle), CallbackQueryUpdate(raw: raw, ..) ->
      case raw.data {
        Some(data) ->
          case regex.check(filter.re, data) {
            True -> Some(handle(new_context(bot, update), data, raw.id))
            False -> None
          }
        None -> None
      }
    _, _ -> None
  }
}

fn loop_handlers(
  bot: BotInstanse(session),
  update: Update,
  handlers: List(Handler(session)),
) {
  case handlers {
    [handler, ..rest] ->
      case do_handle(bot, update, handler) {
        Some(Ok(new_session)) ->
          loop_handlers(BotInstanse(..bot, session: new_session), update, rest)
        Some(Error(e)) ->
          Error(
            "Failed to handle message " <> string.inspect(update) <> ":\n" <> e,
          )
        None -> loop_handlers(bot, update, rest)
      }
    [] -> bot.session_settings.persist_session(bot.key, bot.session)
  }
}
