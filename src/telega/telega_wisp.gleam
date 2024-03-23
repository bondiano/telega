import wisp.{
  type Request as WispRequest, type Response as WispResponse,
  Empty as WispEmptyBody,
}
import gleam/http/response.{Response as HttpResponse}
import gleam/result
import gleam/http/request
import telega.{type Bot}
import gleam/bool
import logging

const secret_header = "x-relegram-bot-api-secret-token"

fn is_secret_token_valid(bot: Bot, req: WispRequest) -> Bool {
  let secret_header_value =
    request.get_header(req, secret_header)
    |> result.unwrap("")

  telega.is_secret_token_valid(bot, secret_header_value)
}

/// Handle incoming requests from the Telegram API.
/// Add this function as a handler to your wisp server.
///
/// ```gleam
/// import telega.{type Bot}
/// import telega/telega_wisp
///
/// fn handle_request(bot: Bot, req: Request) -> Response {
///   use req <- middleware(req)
///   use <- bool.lazy_guard(telega_wisp.is_bot_request(bot, req), fn() {
///     telega_wisp.bot_handler(bot, req)
///   })
///
///   case wisp.path_segments(req) {
///     ["helath"] -> wisp.ok()
///     _ -> wisp.not_found()
///   }
/// }
/// ```
pub fn bot_handler(bot: Bot, req: WispRequest) -> WispResponse {
  use json <- wisp.require_json(req)

  case telega.decode_message(json) {
    Ok(message) -> {
      use <- bool.lazy_guard(is_secret_token_valid(bot, req), fn() {
        HttpResponse(401, [], WispEmptyBody)
      })

      logging.log(logging.Info, "Received message: " <> message.text)
      telega.handle_update(bot, message)

      wisp.ok()
    }
    Error(_) -> {
      logging.log(logging.Error, "Failed to decode message")

      wisp.ok()
    }
  }
}

pub fn is_bot_request(bot: Bot, req: WispRequest) -> Bool {
  case wisp.path_segments(req) {
    [segment] -> {
      case telega.is_webhook_path(bot, segment) {
        True -> True
        False -> False
      }
    }
    _ -> False
  }
}
