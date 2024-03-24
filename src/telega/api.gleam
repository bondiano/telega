//// > It's internal module for working with Telegram API, **not** for public use.

import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/http.{Get, Post}
import gleam/option.{type Option, None, Some}
import gleam/json
import gleam/httpc
import gleam/result
import gleam/dynamic

type TelegramApiRequest {
  TelegramApiPostRequest(
    url: String,
    body: String,
    query: Option(List(#(String, String))),
  )
  TelegramApiGetRequest(url: String, query: Option(List(#(String, String))))
}

fn new_post_request(
  token token: String,
  telegram_url telegram_url: String,
  path path: String,
  body body: String,
  query query: Option(List(#(String, String))),
) {
  let url = telegram_url <> token <> "/" <> path

  TelegramApiPostRequest(url: url, body: body, query: query)
}

fn new_get_request(
  token token: String,
  telegram_url telegram_url: String,
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
      |> result.map(request.set_header(_, "Content-Type", "application/json"))
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

/// **Official reference:** https://core.telegram.org/bots/api#setwebhook
pub fn set_webhook(
  token token: String,
  webhook_url webhook_url: String,
  telegram_url telegram_url: String,
  secret_token secret_token: Option(String),
) -> Result(Response(String), String) {
  let query = [#("url", webhook_url)]
  let query = case secret_token {
    None -> query
    Some(secret_token) -> [#("secret_token", secret_token), ..query]
  }

  new_get_request(
    token: token,
    telegram_url: telegram_url,
    path: "setWebhook",
    query: Some(query),
  )
  |> api_to_request
  |> fetch
}

/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn send_message(
  chat_id chat_id: Int,
  text text: String,
  token token: String,
  telegram_url telegram_url: String,
) -> Result(Response(String), String) {
  new_post_request(
    token: token,
    telegram_url: telegram_url,
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
}
