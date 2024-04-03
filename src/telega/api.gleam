import gleam/json
import gleam/httpc
import gleam/result
import gleam/string
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/http.{Get, Post}
import gleam/option.{type Option, None, Some}
import gleam/dynamic.{type DecodeError, type Dynamic}
import telega/bot.{type Bot, type Context}
import telega/model.{
  type BotCommand, type BotCommandParameters, type Message,
  type SendDiceParameters, type User, type WebhookInfo,
}
import telega/log

const telegram_url = "https://api.telegram.org/bot"

const default_retry_count = 5

const default_retry_delay = 1000

type TelegramApiRequest {
  TelegramApiPostRequest(
    url: String,
    body: String,
    query: Option(List(#(String, String))),
  )
  TelegramApiGetRequest(url: String, query: Option(List(#(String, String))))
}

type ApiResponse(result) {
  ApiResponse(ok: Bool, result: result)
}

// TODO: Support all options from the official reference.
/// Set the webhook URL using [setWebhook](https://core.telegram.org/bots/api#setwebhook) API.
///
/// **Official reference:** https://core.telegram.org/bots/api#setwebhook
pub fn set_webhook(bot: Bot) -> Result(Bool, String) {
  let webhook_url = bot.config.server_url <> "/" <> bot.config.webhook_path
  let query = [
    #("url", webhook_url),
    #("secret_token", bot.config.secret_token),
  ]

  new_get_request(bot, path: "setWebhook", query: Some(query))
  |> fetch(bot)
  |> map_resonse(dynamic.bool)
}

/// Use this method to get current webhook status.
///
/// **Official reference:** https://core.telegram.org/bots/api#getwebhookinfo
pub fn get_webhook_info(bot: Bot) -> Result(WebhookInfo, String) {
  new_get_request(bot, path: "getWebhookInfo", query: None)
  |> fetch(bot)
  |> map_resonse(model.decode_webhook_info)
}

/// Use this method to remove webhook integration if you decide to switch back to [getUpdates](https://core.telegram.org/bots/api#getupdates).
///
/// **Official reference:** https://core.telegram.org/bots/api#deletewebhook
pub fn delete_webhook(bot: Bot) -> Result(Bool, String) {
  new_get_request(bot, path: "deleteWebhook", query: None)
  |> fetch(bot)
  |> map_resonse(dynamic.bool)
}

/// The same as [delete_webhook](#delete_webhook) but also drops all pending updates.
pub fn delete_webhook_and_drop_updates(bot: Bot) -> Result(Bool, String) {
  new_get_request(
    bot,
    path: "deleteWebhook",
    query: Some([#("drop_pending_updates", "true")]),
  )
  |> fetch(bot)
  |> map_resonse(dynamic.bool)
}

/// Use this method to log out from the cloud Bot API server before launching the bot locally.
/// You **must** log out the bot before running it locally, otherwise there is no guarantee that the bot will receive updates.
/// After a successful call, you can immediately log in on a local server, but will not be able to log in back to the cloud Bot API server for 10 minutes.
///
/// **Official reference:** https://core.telegram.org/bots/api#logout
pub fn log_out(bot: Bot) -> Result(Bool, String) {
  new_get_request(bot, path: "logOut", query: None)
  |> fetch(bot)
  |> map_resonse(dynamic.bool)
}

/// Use this method to close the bot instance before moving it from one local server to another.
/// You need to delete the webhook before calling this method to ensure that the bot isn't launched again after server restart.
/// The method will return error 429 in the first 10 minutes after the bot is launched.
///
/// **Official reference:** https://core.telegram.org/bots/api#close
pub fn close(bot: Bot) -> Result(Bool, String) {
  new_get_request(bot, path: "close", query: None)
  |> fetch(bot)
  |> map_resonse(dynamic.bool)
}

// TODO: Support all options from the official reference.
/// Use this method to send text messages.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn reply(ctx ctx: Context, text text: String) -> Result(Message, String) {
  new_post_request(
    ctx.bot,
    path: "sendMessage",
    body: json.object([
        #("chat_id", json.int(ctx.message.raw.chat.id)),
        #("text", json.string(text)),
      ])
      |> json.to_string,
    query: None,
  )
  |> fetch(ctx.bot)
  |> map_resonse(model.decode_message)
}

/// Use this method to change the list of the bot's commands. See [commands documentation](https://core.telegram.org/bots/features#commands) for more details about bot commands.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmycommands
pub fn set_my_commands(
  ctx ctx: Context,
  commands commands: List(BotCommand),
  parameters parameters: Option(BotCommandParameters),
) -> Result(Bool, String) {
  let parameters =
    option.unwrap(parameters, model.new_botcommand_parameters())
    |> model.encode_botcommand_parameters

  let body_json =
    json.object([
      #(
        "commands",
        json.array(commands, fn(command: BotCommand) {
          json.object([
            #("command", json.string(command.command)),
            #("description", json.string(command.description)),
            ..parameters
          ])
        }),
      ),
    ])

  new_post_request(
    ctx.bot,
    path: "setMyCommands",
    body: json.to_string(body_json),
    query: None,
  )
  |> fetch(ctx.bot)
  |> map_resonse(dynamic.bool)
}

/// Use this method to delete the list of the bot's commands for the given scope and user language.
/// After deletion, [higher level commands](https://core.telegram.org/bots/api#determining-list-of-commands) will be shown to affected users.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletemycommands
pub fn delete_my_commands(
  ctx: Context,
  parameters parameters: Option(BotCommandParameters),
) -> Result(Bool, String) {
  let parameters =
    option.unwrap(parameters, model.new_botcommand_parameters())
    |> model.encode_botcommand_parameters

  let body_json = json.object(parameters)

  new_post_request(
    ctx.bot,
    path: "deleteMyCommands",
    body: json.to_string(body_json),
    query: None,
  )
  |> fetch(ctx.bot)
  |> map_resonse(dynamic.bool)
}

/// Use this method to get the current list of the bot's commands for the given scope and user language.
///
/// **Official reference:** https://core.telegram.org/bots/api#getmycommands
pub fn get_my_commands(
  ctx: Context,
  parameters parameters: Option(BotCommandParameters),
) -> Result(List(BotCommand), String) {
  let parameters =
    option.unwrap(parameters, model.new_botcommand_parameters())
    |> model.encode_botcommand_parameters

  let body_json = json.object(parameters)

  new_post_request(
    ctx.bot,
    path: "getMyCommands",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(ctx.bot)
  |> map_resonse(model.decode_bot_command)
}

/// Use this method to send an animated emoji that will display a random value.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddice
pub fn send_dice(
  ctx: Context,
  parameters parameters: Option(SendDiceParameters),
) -> Result(Message, String) {
  let body_json =
    parameters
    |> option.lazy_unwrap(fn() {
      model.new_send_dice_parameters(ctx.message.raw.chat.id)
    })
    |> model.encode_send_dice_parameters

  new_post_request(
    bot: ctx.bot,
    path: "sendDice",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(ctx.bot)
  |> map_resonse(model.decode_message)
}

/// A simple method for testing your bot's authentication token.
///
/// **Official reference:** https://core.telegram.org/bots/api#getme
pub fn get_me(ctx: Context) -> Result(User, String) {
  new_get_request(ctx.bot, path: "getMe", query: None)
  |> fetch(ctx.bot)
  |> map_resonse(model.decode_user)
}

fn build_url(bot: Bot, path: String) -> String {
  let url = option.unwrap(bot.config.tg_api_url, telegram_url)
  url <> bot.config.token <> "/" <> path
}

fn new_post_request(
  bot bot: Bot,
  path path: String,
  body body: String,
  query query: Option(List(#(String, String))),
) {
  TelegramApiPostRequest(url: build_url(bot, path), body: body, query: query)
}

fn new_get_request(
  bot bot: Bot,
  path path: String,
  query query: Option(List(#(String, String))),
) {
  TelegramApiGetRequest(url: build_url(bot, path), query: query)
}

fn set_query(
  api_request: Request(String),
  query: Option(List(#(String, String))),
) -> Request(String) {
  case query {
    None -> api_request
    Some(query) -> {
      request.set_query(api_request, query)
    }
  }
}

fn api_to_request(
  api_request: TelegramApiRequest,
) -> Result(Request(String), String) {
  case api_request {
    TelegramApiGetRequest(url: url, query: query) -> {
      request.to(url)
      |> result.map(request.set_method(_, Get))
      |> result.map(set_query(_, query))
    }
    TelegramApiPostRequest(url: url, query: query, body: body) -> {
      request.to(url)
      |> result.map(request.set_body(_, body))
      |> result.map(request.set_method(_, Post))
      |> result.map(request.set_header(_, "Content-Type", "application/json"))
      |> result.map(set_query(_, query))
    }
  }
  |> result.map_error(fn(_) { "Failed to convert API request to HTTP request" })
}

fn fetch(
  api_request: TelegramApiRequest,
  bot: Bot,
) -> Result(Response(String), String) {
  use api_request <- result.try(api_to_request(api_request))
  let retry_count =
    option.unwrap(bot.config.max_retry_attempts, default_retry_count)

  send_with_retry(api_request, retry_count)
  |> result.map_error(fn(error) {
    log.info("Api request failed with error:" <> string.inspect(error))

    dynamic.string(error)
    |> result.unwrap("Failed to send request")
  })
}

fn send_with_retry(
  api_request: Request(String),
  retries: Int,
) -> Result(Response(String), Dynamic) {
  let response = httpc.send(api_request)

  case retries {
    0 -> response
    _ -> {
      case response {
        Ok(response) -> {
          case response.status {
            429 -> {
              log.warn("Telegram API throttling, HTTP 429 'Too Many Requests'")
              process.sleep(default_retry_delay)
              send_with_retry(api_request, retries - 1)
            }
            _ -> Ok(response)
          }
        }
        Error(_) -> {
          process.sleep(default_retry_delay)
          send_with_retry(api_request, retries - 1)
        }
      }
    }
  }
}

fn map_resonse(
  response: Result(Response(String), String),
  result_decoder: fn(Dynamic) -> Result(a, List(DecodeError)),
) -> Result(a, String) {
  response
  |> result.map(fn(response) {
    let Response(body: body, ..) = response
    let decode = response_decoder(result_decoder)
    json.decode(body, decode)
    |> result.map_error(fn(_) { "Failed to decode response: " <> body })
    |> result.map(fn(response) { response.result })
  })
  |> result.flatten
}

fn response_decoder(result_decoder: fn(Dynamic) -> Result(a, List(DecodeError))) {
  dynamic.decode2(
    ApiResponse,
    dynamic.field("ok", dynamic.bool),
    dynamic.field("result", result_decoder),
  )
}
