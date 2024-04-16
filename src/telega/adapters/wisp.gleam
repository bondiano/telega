import gleam/bool
import gleam/http/request
import gleam/http/response.{Response as HttpResponse}
import gleam/result
import telega.{type Telega}
import telega/log
import telega/update
import wisp.{
  type Request as WispRequest, type Response as WispResponse,
  Empty as WispEmptyBody,
}

const secret_header = "x-relegram-bot-api-secret-token"

/// A middleware function to handle incoming requests from the Telegram API.
/// Handles a request to the bot webhook endpoint, decodes the incoming message,
/// validates the secret token, and passes the message to the bot for processing.
///
/// ```gleam
/// import wisp.{type Request, type Response}
/// import telega.{type Bot}
/// import telega/adapters/wisp as telega_wisp
///
/// fn handle_request(req: Request, bot: Bot) -> Response {
///   use <- telega_wisp.handle_bot(req)
///   // ...
/// }
/// ```
pub fn handle_bot(
  request req: WispRequest,
  telega telega: Telega(session),
  next handler: fn() -> WispResponse,
) -> WispResponse {
  use <- bool.lazy_guard(!is_bot_request(telega, req), fn() { handler() })
  log.info("Received request from Telegram API")
  use json <- wisp.require_json(req)

  case update.decode(json) {
    Ok(message) -> {
      use <- bool.lazy_guard(is_secret_token_valid(telega, req), fn() {
        HttpResponse(401, [], WispEmptyBody)
      })
      case telega.handle_update(telega, message) {
        Ok(_) -> wisp.ok()
        Error(error) -> {
          log.error("Failed to handle message: " <> error)
          wisp.internal_server_error()
        }
      }
    }
    Error(error) -> {
      log.error("Failed to decode message:\n" <> error)
      wisp.internal_server_error()
    }
  }
}

fn is_secret_token_valid(telega: Telega(session), req: WispRequest) -> Bool {
  let secret_header_value =
    request.get_header(req, secret_header)
    |> result.unwrap("")

  telega.is_secret_token_valid(telega, secret_header_value)
}

fn is_bot_request(telega: Telega(session), req: WispRequest) -> Bool {
  case wisp.path_segments(req) {
    [segment] -> {
      case telega.is_webhook_path(telega, segment) {
        True -> True
        False -> False
      }
    }
    _ -> False
  }
}
