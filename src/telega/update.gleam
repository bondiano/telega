import gleam/bool
import gleam/string
import gleam/list
import gleam/result
import gleam/option.{type Option, None, Some}
import gleam/dynamic.{type Dynamic}
import telega/model.{
  type CallbackQuery, type Message, type MessageEntity,
  type Update as ModelUpdate,
}

/// Messages represent the data that the bot receives from the Telegram API.
pub type Update {
  TextUpdate(chat_id: Int, text: String, raw: Message)
  CommandUpdate(chat_id: Int, command: Command, raw: Message)
  CallbackQueryUpdate(from_id: Int, raw: CallbackQuery)
  UnknownUpdate(raw: ModelUpdate)
}

pub type Command {
  /// Represents a command message.
  Command(
    /// Whole command message
    text: String,
    /// Command name without the leading slash
    command: String,
    /// The command arguments, if any.
    payload: Option(String),
  )
}

/// Decode a update from the Telegram API to `Update` instanse.
pub fn decode(json: Dynamic) -> Result(Update, String) {
  use raw_update <- result.try(
    model.decode_update(json)
    |> result.map_error(fn(e) { "Cannot decode update: " <> string.inspect(e) }),
  )
  use <- try_decode_to_callback_query(raw_update)
  use <- try_to_decode_message_or_command(raw_update)

  Ok(UnknownUpdate(raw_update))
}

fn try_decode_to_callback_query(
  raw_update: ModelUpdate,
  on_none: fn() -> Result(Update, String),
) -> Result(Update, String) {
  case raw_update.callback_query {
    Some(callback_query) ->
      Ok(CallbackQueryUpdate(
        from_id: callback_query.from.id,
        raw: callback_query,
      ))
    None -> on_none()
  }
}

fn try_to_decode_message_or_command(
  raw_update: ModelUpdate,
  on_none: fn() -> Result(Update, String),
) {
  case raw_update.message {
    Some(message) -> {
      case message.text {
        Some(text) -> {
          case is_command_update(text, raw_update) {
            True ->
              Ok(CommandUpdate(
                chat_id: message.chat.id,
                command: extract_command(text),
                raw: message,
              ))
            False ->
              Ok(TextUpdate(chat_id: message.chat.id, text: text, raw: message))
          }
        }
        None -> on_none()
      }
    }
    None -> on_none()
  }
}

fn is_command_update(text: String, raw_update: ModelUpdate) -> Bool {
  use <- bool.guard(!string.starts_with(text, "/"), False)

  case raw_update.message {
    Some(message) ->
      case message.entities {
        Some(entities) -> {
          let is_command_entity = fn(entity: MessageEntity) -> Bool {
            entity.entity_type == "bot_command"
            && entity.offset == 0
            && entity.length == string.length(text)
          }

          list.any(entities, is_command_entity)
        }
        None -> False
      }
    None -> False
  }
}

fn extract_command(text: String) -> Command {
  case string.split(text, " ") {
    [command, ..payload] ->
      Command(
        text: text,
        command: string.drop_left(command, 1),
        payload: payload
          |> string.join(" ")
          |> Some,
      )
    [] -> Command(text: text, command: "", payload: None)
  }
}
