import gleam/bool
import gleam/string
import gleam/list
import gleam/option.{None, Some}
import gleam/dynamic.{type Dynamic}
import gleam/result.{try}
import telega/model.{type Message as RawMessage, type MessageEntity}

pub type MessageKind {
  CommonMessage
  CommandMessage
  TextMessage
}

/// Messages represent the data that the bot receives from the Telegram API.
pub type Message {
  Message(
    kind: MessageKind,
    /// Raw message data from the Telegram API.
    raw: RawMessage,
  )
}

/// Decode a message from the Telegram API.
pub fn decode(json: Dynamic) -> Result(Message, dynamic.DecodeErrors) {
  use update <- try(model.decode_update(json))

  Ok(raw_message_to_message(update.message))
}

fn is_command_message(text: String, raw_message: RawMessage) -> Bool {
  use <- bool.guard(!string.starts_with(text, "/"), False)

  case raw_message.entities {
    None -> False
    Some(entities) -> {
      let is_command_entity = fn(entity: MessageEntity) -> Bool {
        entity.entity_type == "bot_command"
        && entity.offset == 0
        && entity.length == string.length(text)
      }

      list.any(entities, is_command_entity)
    }
  }
}

fn raw_message_to_message(raw_message: RawMessage) -> Message {
  case raw_message.text {
    None -> Message(raw: raw_message, kind: CommonMessage)
    Some(text) -> {
      case is_command_message(text, raw_message) {
        True -> Message(raw: raw_message, kind: CommandMessage)
        False -> Message(raw: raw_message, kind: TextMessage)
      }
    }
  }
}
