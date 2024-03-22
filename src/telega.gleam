import gleam/result.{try}
import gleam/dynamic.{type Dynamic}
import telega/api
import wisp.{type Request, type Response}
import logging

type MessageUpdate {
  MessageUpdate(message: Message)
}

pub type Chat {
  Chat(id: Int)
}

pub type Message {
  TextMessage(text: String, chat: Chat)
}

pub type Handler =
  fn(Bot, Message) -> Result(Nil, Nil)

pub opaque type Bot {
  Bot(
    token: String,
    server_url: String,
    secret: String,
    handlers: List(Handler),
  )
}

pub fn new(
  token token: String,
  url server_url: String,
  secret secret: String,
) -> Bot {
  Bot(token: token, server_url: server_url, secret: secret, handlers: [])
}

pub fn set_webhook(bot: Bot) -> Result(Bool, String) {
  let webhook_url = bot.server_url <> "/" <> bot.secret
  use response <- try(api.set_webhook(bot.token, webhook_url))

  case response.status {
    200 -> Ok(True)
    _ -> Error("Failed to set webhook")
  }
}

fn decode_message(json: Dynamic) -> Result(Message, dynamic.DecodeErrors) {
  let message_update_decoder =
    dynamic.decode1(
      MessageUpdate,
      dynamic.field(
        "message",
        dynamic.decode2(
          TextMessage,
          dynamic.field("text", dynamic.string),
          dynamic.field(
            "chat",
            dynamic.decode1(Chat, dynamic.field("id", dynamic.int)),
          ),
        ),
      ),
    )

  use message_update <- try(message_update_decoder(json))

  Ok(message_update.message)
}

pub fn is_bot_request(bot: Bot, req: Request) -> Bool {
  case wisp.path_segments(req) {
    [segment] if segment == bot.secret -> True
    _ -> False
  }
}

fn handle_update_loop(
  bot: Bot,
  message: Message,
  handlers: List(Handler),
) -> Nil {
  case handlers {
    [handler, ..rest] -> {
      case handler(bot, message) {
        Ok(_) -> handle_update_loop(bot, message, rest)
        Error(_) -> {
          logging.log(logging.Error, "Failed to handle message")
          Nil
        }
      }
    }
    _ -> Nil
  }
}

fn handle_update(bot: Bot, message: Message) -> Nil {
  handle_update_loop(bot, message, bot.handlers)
}

pub fn bot_handler(bot: Bot, req: Request) -> Response {
  use json <- wisp.require_json(req)

  case decode_message(json) {
    Ok(message) -> {
      logging.log(logging.Info, "Received message: " <> message.text)
      handle_update(bot, message)

      wisp.ok()
    }
    Error(_) -> {
      logging.log(logging.Error, "Failed to decode message")

      wisp.ok()
    }
  }
}

pub fn reply(bot: Bot, message: Message, text: String) -> Result(Nil, Nil) {
  api.send_text(bot.token, message.chat.id, text)
  |> result.map(fn(_) { Nil })
  |> result.nil_error
}

pub fn add_handler(bot: Bot, handler: Handler) -> Bot {
  Bot(..bot, handlers: [handler, ..bot.handlers])
}
