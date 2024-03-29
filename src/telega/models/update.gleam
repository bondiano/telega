import gleam/dynamic.{type Dynamic}
import telega/models/message.{type Message}

pub type Update {
  /// **Official reference:** https://core.telegram.org/bots/api#update
  Update(
    message: Message,
    /// The update's unique identifier.
    update_id: Int,
  )
}

/// Decode a message from the Telegram API.
pub fn decode(json: Dynamic) -> Result(Update, dynamic.DecodeErrors) {
  json
  |> dynamic.decode2(
    Update,
    dynamic.field("message", message.decode),
    dynamic.field("update_id", dynamic.int),
  )
}
