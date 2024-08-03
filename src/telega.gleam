import gleam/bool
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/otp/supervisor
import gleam/result
import gleam/string
import telega/api
import telega/bot.{
  type CallbackQueryFilter, type Context, type Handler, type Hears,
  type RegistryMessage, type SessionSettings, CallbackQueryFilter, Context,
  HandleAll, HandleBotRegistryMessage, HandleCallbackQuery, HandleCommand,
  HandleCommands, HandleHears, HandleText, SessionSettings,
}
import telega/internal/config.{type Config}
import telega/log
import telega/model.{type User}
import telega/update.{type Command, type Update}

pub opaque type Telega(session) {
  Telega(
    config: Config,
    bot_info: User,
    handlers: List(Handler(session)),
    session_settings: SessionSettings(session),
    registry_subject: Subject(RegistryMessage),
  )
}

pub opaque type TelegaBuilder(session) {
  TelegaBuilder(
    config: Config,
    handlers: List(Handler(session)),
    session_settings: Option(SessionSettings(session)),
    registry_subject: Option(Subject(RegistryMessage)),
  )
}

/// Check if a path is the webhook path for the bot.
///
/// Usefull if you plan to implement own adapter.
pub fn is_webhook_path(telega: Telega(session), path: String) -> Bool {
  telega.config.webhook_path == path
}

/// Check if a secret token is valid.
///
/// Usefull if you plan to implement own adapter.
pub fn is_secret_token_valid(telega: Telega(session), token: String) -> Bool {
  telega.config.secret_token == token
}

/// Create a new Telega instance.
pub fn new(
  token token: String,
  url server_url: String,
  webhook_path webhook_path: String,
  secret_token secret_token: Option(String),
) -> TelegaBuilder(session) {
  TelegaBuilder(
    handlers: [],
    config: config.new(token:, webhook_path:, secret_token:, url: server_url),
    registry_subject: None,
    session_settings: None,
  )
}

/// Handles all messages.
pub fn handle_all(
  bot builder: TelegaBuilder(session),
  handler handler: fn(Context(session)) -> Result(session, String),
) -> TelegaBuilder(session) {
  TelegaBuilder(..builder, handlers: [HandleAll(handler), ..builder.handlers])
}

/// Stops bot message handling and waits for any message.
pub fn wait_any(
  ctx ctx: Context(session),
  continue continue: fn(Context(session)) -> Result(session, String),
) -> Result(session, String) {
  bot.wait_handler(ctx, HandleAll(continue))
}

/// Handles a specific command.
pub fn handle_command(
  bot builder: TelegaBuilder(session),
  command command: String,
  handler handler: fn(Context(session), Command) -> Result(session, String),
) -> TelegaBuilder(session) {
  TelegaBuilder(
    ..builder,
    handlers: [HandleCommand(command, handler), ..builder.handlers],
  )
}

pub fn wait_command(
  ctx ctx: Context(session),
  command command: String,
  continue continue: fn(Context(session), Command) -> Result(session, String),
) -> Result(session, String) {
  bot.wait_handler(ctx, HandleCommand(command, continue))
}

/// Handles multiple commands.
pub fn handle_commands(
  bot builder: TelegaBuilder(session),
  commands commands: List(String),
  handler handler: fn(Context(session), Command) -> Result(session, String),
) -> TelegaBuilder(session) {
  TelegaBuilder(
    ..builder,
    handlers: [HandleCommands(commands, handler), ..builder.handlers],
  )
}

pub fn wait_commands(
  ctx ctx: Context(session),
  commands commands: List(String),
  continue continue: fn(Context(session), Command) -> Result(session, String),
) -> Result(session, String) {
  bot.wait_handler(ctx, HandleCommands(commands, continue))
}

/// Handles text messages.
pub fn handle_text(
  bot builder: TelegaBuilder(session),
  handler handler: fn(Context(session), String) -> Result(session, String),
) -> TelegaBuilder(session) {
  TelegaBuilder(..builder, handlers: [HandleText(handler), ..builder.handlers])
}

pub fn wait_text(
  ctx ctx: Context(session),
  continue continue: fn(Context(session), String) -> Result(session, String),
) -> Result(session, String) {
  bot.wait_handler(ctx, HandleText(continue))
}

/// Handles messages that match the given `Hears`.
pub fn handle_hears(
  bot builder: TelegaBuilder(session),
  hears hears: Hears,
  handler handler: fn(Context(session), String) -> Result(session, String),
) -> TelegaBuilder(session) {
  TelegaBuilder(
    ..builder,
    handlers: [HandleHears(hears, handler), ..builder.handlers],
  )
}

pub fn wait_hears(
  ctx ctx: Context(session),
  hears hears: Hears,
  continue continue: fn(Context(session), String) -> Result(session, String),
) {
  bot.wait_handler(ctx, HandleHears(hears, continue))
}

/// Handles messages from inline keyboard callback.
pub fn handle_callback_query(
  bot builder: TelegaBuilder(session),
  filter filter: CallbackQueryFilter,
  handler handler: fn(Context(session), String, String) ->
    Result(session, String),
) -> TelegaBuilder(session) {
  TelegaBuilder(
    ..builder,
    handlers: [HandleCallbackQuery(filter, handler), ..builder.handlers],
  )
}

pub fn wait_callback_query(
  ctx ctx: Context(session),
  filter filter: CallbackQueryFilter,
  continue continue: fn(Context(session), String, String) ->
    Result(session, String),
) -> Result(session, String) {
  bot.wait_handler(ctx, HandleCallbackQuery(filter, continue))
}

/// Log the message and error message if the handler fails.
pub fn log_context(
  ctx: Context(session),
  prefix: String,
  handler: fn() -> Result(session, String),
) -> Result(session, String) {
  let prefix = "[" <> prefix <> "] "

  log.info(prefix <> "Received update: " <> string.inspect(ctx.update))

  handler()
  |> result.map_error(fn(e) {
    log.error(prefix <> "Handler failed: " <> string.inspect(e))
    e
  })
}

/// Construct a session settings.
pub fn with_session_settings(
  builder: TelegaBuilder(session),
  persist_session persist_session: fn(String, session) ->
    Result(session, String),
  get_session get_session: fn(String) -> Result(session, String),
) -> TelegaBuilder(session) {
  TelegaBuilder(
    ..builder,
    session_settings: Some(SessionSettings(
      persist_session: persist_session,
      get_session: get_session,
    )),
  )
}

fn nil_session_settings(builder: TelegaBuilder(Nil)) -> TelegaBuilder(Nil) {
  TelegaBuilder(
    ..builder,
    session_settings: Some(
      SessionSettings(persist_session: fn(_, _) { Ok(Nil) }, get_session: fn(_) {
        Ok(Nil)
      }),
    ),
  )
}

/// Initialize a Telega instance with a `Nil` session.
/// Usefulwhen you don't need to persist the session.
pub fn init_nil_session(
  builder: TelegaBuilder(Nil),
) -> Result(Telega(Nil), String) {
  builder
  |> nil_session_settings
  |> init
}

/// Initialize a Telega instance.
/// This function should be called after all handlers are added.
/// It will set the webhook and start the `Registry`.
pub fn init(builder: TelegaBuilder(session)) -> Result(Telega(session), String) {
  use is_ok <- result.try(bot.set_webhook(builder.config))
  use <- bool.guard(!is_ok, Error("Failed to set webhook"))

  use bot_info <- result.try(api.get_me(builder.config.api))

  let session_settings =
    option.to_result(
      builder.session_settings,
      "Session settings not initialized",
    )

  use session_settings <- result.try(session_settings)

  let telega_subject = process.new_subject()
  let registry_actor =
    supervisor.supervisor(fn(_) {
      bot.start_registry(
        bot_info:,
        session_settings:,
        config: builder.config,
        handlers: builder.handlers,
        root_subject: telega_subject,
      )
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

  Ok(Telega(
    bot_info:,
    registry_subject:,
    session_settings:,
    config: builder.config,
    handlers: builder.handlers,
  ))
}

/// Handle an update from the Telegram API.
pub fn handle_update(
  telega: Telega(session),
  update: Update,
) -> Result(Nil, String) {
  Ok(actor.send(
    telega.registry_subject,
    HandleBotRegistryMessage(update: update),
  ))
}
