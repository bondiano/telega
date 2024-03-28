import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/http.{Get, Post}
import gleam/option.{type Option, None, Some}
import gleam/json
import gleam/httpc
import gleam/result
import gleam/dynamic.{type DecodeError, type Dynamic}
import telega/types/message.{type Message}
import telega/types/bot_command.{type BotCommand, type BotCommandOptions}

const telegram_url = "https://api.telegram.org/bot"

type TelegramApiRequest {
  TelegramApiPostRequest(
    url: String,
    body: String,
    query: Option(List(#(String, String))),
  )
  TelegramApiGetRequest(url: String, query: Option(List(#(String, String))))
}

pub type ApiResponse(result) {
  ApiResponse(ok: Bool, result: result)
}

// TODO: Support all options
/// **Official reference:** https://core.telegram.org/bots/api#setwebhook
pub fn set_webhook(
  token token: String,
  webhook_url webhook_url: String,
  secret_token secret_token: Option(String),
) -> Result(Bool, String) {
  let query = [#("url", webhook_url)]
  let query = case secret_token {
    None -> query
    Some(secret_token) -> [#("secret_token", secret_token), ..query]
  }

  new_get_request(token: token, path: "setWebhook", query: Some(query))
  |> api_to_request
  |> fetch
  |> map_resonse(dynamic.bool)
}

// TODO: Support all options
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn send_message(
  token token: String,
  chat_id chat_id: Int,
  text text: String,
) -> Result(Message, String) {
  new_post_request(
    token: token,
    path: "sendMessage",
    body: json.object([
        #("chat_id", json.int(chat_id)),
        #("text", json.string(text)),
      ])
      |> json.to_string,
    query: None,
  )
  |> api_to_request
  |> fetch
  |> map_resonse(message.decode)
}

/// **Official reference:** https://core.telegram.org/bots/api#setmycommands
pub fn set_my_commands(
  token token: String,
  commands commands: List(BotCommand),
  options options: Option(BotCommandOptions),
) -> Result(Bool, String) {
  let options =
    option.unwrap(
      options,
      bot_command.BotCommandOptions(scope: None, language_code: None),
    )
    |> bot_command.encode_botcommand_options

  let body_json =
    json.object([
      #(
        "commands",
        json.array(commands, fn(command: BotCommand) {
          json.object([
            #("command", json.string(command.command)),
            #("description", json.string(command.description)),
            ..options
          ])
        }),
      ),
    ])

  new_post_request(
    token: token,
    path: "setMyCommands",
    body: json.to_string(body_json),
    query: None,
  )
  |> api_to_request
  |> fetch
  |> map_resonse(dynamic.bool)
}

/// **Official reference:** https://core.telegram.org/bots/api#deletemycommands
pub fn delete_my_commands(
  token token: String,
  options options: Option(BotCommandOptions),
) -> Result(Bool, String) {
  let options =
    option.unwrap(
      options,
      bot_command.BotCommandOptions(scope: None, language_code: None),
    )
    |> bot_command.encode_botcommand_options

  let body_json = json.object(options)

  new_post_request(
    token: token,
    path: "deleteMyCommands",
    body: json.to_string(body_json),
    query: None,
  )
  |> api_to_request
  |> fetch
  |> map_resonse(dynamic.bool)
}

/// **Official reference:** https://core.telegram.org/bots/api#getmycommands
pub fn get_my_commands(
  token token: String,
  options options: Option(BotCommandOptions),
) -> Result(List(BotCommand), String) {
  let options =
    option.unwrap(
      options,
      bot_command.BotCommandOptions(scope: None, language_code: None),
    )
    |> bot_command.encode_botcommand_options

  let body_json = json.object(options)

  new_post_request(
    token: token,
    path: "getMyCommands",
    query: None,
    body: json.to_string(body_json),
  )
  |> api_to_request
  |> fetch
  |> map_resonse(bot_command.decode)
}

fn new_post_request(
  token token: String,
  path path: String,
  body body: String,
  query query: Option(List(#(String, String))),
) {
  let url = telegram_url <> token <> "/" <> path

  TelegramApiPostRequest(url: url, body: body, query: query)
}

fn new_get_request(
  token token: String,
  path path: String,
  query query: Option(List(#(String, String))),
) {
  let url = telegram_url <> token <> "/" <> path

  TelegramApiGetRequest(url: url, query: query)
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

fn fetch(api_request: Result(Request(String), String)) {
  use api_request <- result.try(api_request)

  httpc.send(api_request)
  |> result.map_error(fn(error) {
    dynamic.string(error)
    |> result.unwrap("Failed to send request")
  })
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
