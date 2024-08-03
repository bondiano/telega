//// This module provides an interface for interacting with the Telegram Bot API.
//// It will be useful if you want to interact with the Telegram Bot API directly, without running a bot.
//// But it will be more convenient to use the `reply` module in bot handlers.

import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/httpc
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import telega/log
import telega/model.{
  type AnswerCallbackQueryParameters, type BotCommand, type BotCommandParameters,
  type EditMessageTextParameters, type EditMessageTextResult, type File,
  type ForwardMessageParameters, type Message as ModelMessage,
  type SendDiceParameters, type SendMessageParameters, type User,
  type WebhookInfo,
}

const default_retry_delay = 1000

pub type TelegramApiConfig {
  TelegramApiConfig(
    token: String,
    /// The maximum number of times to retry sending a API message. Default is 3.
    max_retry_attempts: Int,
    /// The Telegram Bot API URL. Default is "https://api.telegram.org".
    /// This is useful for running [a local server](https://core.telegram.org/bots/api#using-a-local-bot-api-server).
    tg_api_url: String,
  )
}

pub fn new_api_config(token token: String) -> TelegramApiConfig {
  TelegramApiConfig(
    token,
    max_retry_attempts: 3,
    tg_api_url: "https://api.telegram.org",
  )
}

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
pub fn set_webhook(
  config config: TelegramApiConfig,
  parameters parameters: model.SetWebhookParameters,
) -> Result(Bool, String) {
  let body = model.encode_set_webhook_parameters(parameters)

  new_post_request(
    config,
    path: "setWebhook",
    body: json.to_string(body),
    query: None,
  )
  |> fetch(config)
  |> map_resonse(dynamic.bool)
}

/// Use this method to get current webhook status.
///
/// **Official reference:** https://core.telegram.org/bots/api#getwebhookinfo
pub fn get_webhook_info(
  config config: TelegramApiConfig,
) -> Result(WebhookInfo, String) {
  new_get_request(config, path: "getWebhookInfo", query: None)
  |> fetch(config)
  |> map_resonse(model.decode_webhook_info)
}

/// Use this method to remove webhook integration if you decide to switch back to [getUpdates](https://core.telegram.org/bots/api#getupdates).
///
/// **Official reference:** https://core.telegram.org/bots/api#deletewebhook
pub fn delete_webhook(config config: TelegramApiConfig) -> Result(Bool, String) {
  new_get_request(config, path: "deleteWebhook", query: None)
  |> fetch(config)
  |> map_resonse(dynamic.bool)
}

/// The same as [delete_webhook](#delete_webhook) but also drops all pending updates.
pub fn delete_webhook_and_drop_updates(
  config config: TelegramApiConfig,
) -> Result(Bool, String) {
  new_get_request(
    config,
    path: "deleteWebhook",
    query: Some([#("drop_pending_updates", "true")]),
  )
  |> fetch(config)
  |> map_resonse(dynamic.bool)
}

/// Use this method to log out from the cloud Bot API server before launching the bot locally.
/// You **must** log out the bot before running it locally, otherwise there is no guarantee that the bot will receive updates.
/// After a successful call, you can immediately log in on a local server, but will not be able to log in back to the cloud Bot API server for 10 minutes.
///
/// **Official reference:** https://core.telegram.org/bots/api#logout
pub fn log_out(config config: TelegramApiConfig) -> Result(Bool, String) {
  new_get_request(config, path: "logOut", query: None)
  |> fetch(config)
  |> map_resonse(dynamic.bool)
}

/// Use this method to close the bot instance before moving it from one local server to another.
/// You need to delete the webhook before calling this method to ensure that the bot isn't launched again after server restart.
/// The method will return error 429 in the first 10 minutes after the bot is launched.
///
/// **Official reference:** https://core.telegram.org/bots/api#close
pub fn close(config config: TelegramApiConfig) -> Result(Bool, String) {
  new_get_request(config, path: "close", query: None)
  |> fetch(config)
  |> map_resonse(dynamic.bool)
}

/// Use this method to send text messages with additional parameters.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn send_message(
  config config: TelegramApiConfig,
  parameters parameters: SendMessageParameters,
) -> Result(ModelMessage, String) {
  let body_json = model.encode_send_message_parameters(parameters)

  new_post_request(
    config,
    path: "sendMessage",
    body: json.to_string(body_json),
    query: None,
  )
  |> fetch(config)
  |> map_resonse(model.decode_message)
}

/// Use this method to change the list of the bot's commands. See [commands documentation](https://core.telegram.org/bots/features#commands) for more details about bot commands.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmycommands
pub fn set_my_commands(
  config config: TelegramApiConfig,
  commands commands: List(BotCommand),
  parameters parameters: Option(BotCommandParameters),
) -> Result(Bool, String) {
  let parameters =
    option.unwrap(parameters, model.default_botcommand_parameters())
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
    config,
    path: "setMyCommands",
    body: json.to_string(body_json),
    query: None,
  )
  |> fetch(config)
  |> map_resonse(dynamic.bool)
}

/// Use this method to delete the list of the bot's commands for the given scope and user language.
/// After deletion, [higher level commands](https://core.telegram.org/bots/api#determining-list-of-commands) will be shown to affected users.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletemycommands
pub fn delete_my_commands(
  config config: TelegramApiConfig,
  parameters parameters: Option(BotCommandParameters),
) -> Result(Bool, String) {
  let parameters =
    option.unwrap(parameters, model.default_botcommand_parameters())
    |> model.encode_botcommand_parameters

  let body_json = json.object(parameters)

  new_post_request(
    config,
    path: "deleteMyCommands",
    body: json.to_string(body_json),
    query: None,
  )
  |> fetch(config)
  |> map_resonse(dynamic.bool)
}

/// Use this method to get the current list of the bot's commands for the given scope and user language.
///
/// **Official reference:** https://core.telegram.org/bots/api#getmycommands
pub fn get_my_commands(
  config config: TelegramApiConfig,
  parameters parameters: Option(BotCommandParameters),
) -> Result(List(BotCommand), String) {
  let parameters =
    option.unwrap(parameters, model.default_botcommand_parameters())
    |> model.encode_botcommand_parameters

  let body_json = json.object(parameters)

  new_post_request(
    config,
    path: "getMyCommands",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_resonse(model.decode_bot_command)
}

/// Use this method to send an animated emoji that will display a random value.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddice
pub fn send_dice(
  config config: TelegramApiConfig,
  parameters parameters: SendDiceParameters,
) -> Result(ModelMessage, String) {
  let body_json = model.encode_send_dice_parameters(parameters)

  new_post_request(
    config:,
    path: "sendDice",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_resonse(model.decode_message)
}

/// A simple method for testing your bot's authentication token.
///
/// **Official reference:** https://core.telegram.org/bots/api#getme
pub fn get_me(config config: TelegramApiConfig) -> Result(User, String) {
  new_get_request(config, path: "getMe", query: None)
  |> fetch(config)
  |> map_resonse(model.decode_user)
}

/// Use this method to send answers to callback queries sent from inline keyboards.
/// The answer will be displayed to the user as a notification at the top of the chat screen or as an alert.
/// On success, _True_ is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#answercallbackquery
pub fn answer_callback_query(
  config config: TelegramApiConfig,
  parameters parameters: AnswerCallbackQueryParameters,
) -> Result(Bool, String) {
  let body_json = model.encode_answer_callback_query_parameters(parameters)

  new_post_request(
    config:,
    path: "answerCallbackQuery",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_resonse(dynamic.bool)
}

/// Use this method to edit text and game messages.
/// On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagetext
pub fn edit_message_text(
  config config: TelegramApiConfig,
  parameters parameters: EditMessageTextParameters,
) -> Result(EditMessageTextResult, String) {
  let body_json = model.encode_edit_message_text_parameters(parameters)

  new_post_request(
    config:,
    path: "editMessageText",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_resonse(model.decode_edit_message_text_result)
}

/// Use this method to forward messages of any kind. Service messages and messages with protected content can't be forwarded.
/// On success, the sent Message is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#forwardmessage
pub fn forward_message(
  config config: TelegramApiConfig,
  parameters parameters: ForwardMessageParameters,
) -> Result(ModelMessage, String) {
  let body_json = model.encode_forward_message_parameters(parameters)

  new_post_request(
    config:,
    path: "forwardMessage",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_resonse(model.decode_message)
}

fn build_url(config: TelegramApiConfig, path: String) -> String {
  config.tg_api_url <> config.token <> "/" <> path
}

pub fn get_file(
  config config: TelegramApiConfig,
  file_id file_id: String,
) -> Result(File, String) {
  new_get_request(config, path: "getFile", query: Some([#("file_id", file_id)]))
  |> fetch(config)
  |> map_resonse(model.decode_file)
}

fn new_post_request(
  config config: TelegramApiConfig,
  path path: String,
  body body: String,
  query query: Option(List(#(String, String))),
) {
  TelegramApiPostRequest(url: build_url(config, path), body: body, query: query)
}

fn new_get_request(
  config config: TelegramApiConfig,
  path path: String,
  query query: Option(List(#(String, String))),
) {
  TelegramApiGetRequest(url: build_url(config, path), query: query)
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
  |> result.map_error(fn(error) {
    "Failed to convert API request to HTTP request: " <> string.inspect(error)
  })
}

fn map_resonse(
  response: Result(Response(String), String),
  result_decoder: fn(Dynamic) -> Result(a, List(DecodeError)),
) -> Result(a, String) {
  response
  |> result.map(fn(response) {
    response_decoder(result_decoder)
    |> json.decode(response.body, _)
    |> result.replace_error("Failed to decode response: " <> response.body)
    |> result.map(fn(response) { response.result })
  })
  |> result.flatten
}

// TODO: decode error
fn response_decoder(result_decoder: fn(Dynamic) -> Result(a, List(DecodeError))) {
  dynamic.decode2(
    ApiResponse,
    dynamic.field("ok", dynamic.bool),
    dynamic.field("result", result_decoder),
  )
}

// TODO: add rate limit handling
fn fetch(
  api_request: TelegramApiRequest,
  config: TelegramApiConfig,
) -> Result(Response(String), String) {
  use api_request <- result.try(api_to_request(api_request))

  send_with_retry(api_request, config.max_retry_attempts)
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
              // TODO: remake it with smart request balancer
              // https://github.com/energizer91/smart-request-balancer/tree/master - for reference
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
