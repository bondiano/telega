import gleam/list
import gleam/json.{type Json}
import gleam/option.{type Option, None}
import telega/models/reply.{type ReplyParameters}
import telega/models/common

pub type SendDiceParameters {
  SendDiceParameters(
    chat_id: Int,
    /// Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
    message_thread_id: Option(Int),
    /// Emoji on which the dice throw animation is based. Currently, must be one of "🎲", "🎯", "🏀", "⚽", "🎳", or "🎰". Dice can have values 1-6 for "🎲", "🎯" and "🎳", values 1-5 for "🏀" and "⚽", and values 1-64 for "🎰". Defaults to "🎲"
    emoji: Option(String),
    /// Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
    disable_notification: Option(Bool),
    /// Protects the contents of the sent message from forwarding
    protect_content: Option(Bool),
    /// Description of the message to reply to
    reply_parameters: Option(ReplyParameters),
  )
}

pub fn new_send_dice_parameters(chat_id chat_id: Int) -> SendDiceParameters {
  SendDiceParameters(
    chat_id: chat_id,
    message_thread_id: None,
    emoji: None,
    disable_notification: None,
    protect_content: None,
    reply_parameters: None,
  )
}

pub fn encode_send_dice_parameters(params: SendDiceParameters) -> Json {
  let chat_id = [#("chat_id", json.int(params.chat_id))]
  let message_thread_id =
    common.option_to_json_object_list(
      params.message_thread_id,
      "message_thread_id",
      json.int,
    )
  let emoji =
    common.option_to_json_object_list(params.emoji, "emoji", json.string)
  let disable_notification =
    common.option_to_json_object_list(
      params.disable_notification,
      "disable_notification",
      json.bool,
    )
  let protect_content =
    common.option_to_json_object_list(
      params.protect_content,
      "protect_content",
      json.bool,
    )
  let reply_parameters =
    common.option_to_json_object_list(
      params.reply_parameters,
      "reply_parameters",
      reply.encode_reply_parameters,
    )

  [
    chat_id,
    message_thread_id,
    emoji,
    disable_notification,
    protect_content,
    reply_parameters,
  ]
  |> list.concat
  |> json.object
}
