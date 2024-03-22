import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/http.{Post}
import gleam/json
import gleam/httpc
import gleam/result
import gleam/dynamic
import logging

const base_url = "https://api.telegram.org/bot"

fn fetch(request: Request(String)) -> Result(Response(String), String) {
  request
  |> httpc.send
  |> result.map_error(fn(error) {
    dynamic.string(error)
    |> result.unwrap("Failed to send request")
  })
}

fn build_post_request(url: String, body: String) -> Result(Request(String), Nil) {
  request.to(url)
  |> result.map(request.set_body(_, body))
  |> result.map(request.set_method(_, Post))
  |> result.map(request.set_header(_, "Content-Type", "application/json"))
}

fn build_webhook_request(
  token: String,
  webhook_url: String,
) -> Result(Request(String), String) {
  let webhook_url = base_url <> token <> "/setWebhook?url=" <> webhook_url

  logging.log(logging.Debug, "Webhook URL: " <> webhook_url)

  request.to(webhook_url)
  |> result.map_error(fn(_) { "Failed to build webhook request" })
}

pub fn set_webhook(
  token: String,
  webhook_url: String,
) -> Result(Response(String), String) {
  build_webhook_request(token, webhook_url)
  |> result.then(fetch)
}

fn build_send_text_request(
  token: String,
  chat_id: Int,
  message: String,
) -> Result(Request(String), String) {
  let message =
    json.object([
      #("chat_id", json.int(chat_id)),
      #("text", json.string(message)),
    ])
    |> json.to_string

  let send_message_url = base_url <> token <> "/sendMessage"

  build_post_request(send_message_url, message)
  |> result.map_error(fn(_) { "Failed to build sendMessage request" })
}

pub fn send_text(
  token: String,
  chat_id: Int,
  message: String,
) -> Result(Response(String), String) {
  build_send_text_request(token, chat_id, message)
  |> result.then(fetch)
}
