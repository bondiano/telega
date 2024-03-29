import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option}
import telega/models/common.{type IntOrString}
import telega/models/message_entity.{type MessageEntity}
import telega/models/keyboard.{type InlineKeyboardButton, type Keyboard}

pub type ReplyParameters {
  /// Describes reply parameters for the message that is being sent.
  /// **Official reference:** https://core.telegram.org/bots/api#replyparameters
  ReplyParameters(
    /// Identifier of the message that will be replied to in the current chat, or in the chat chat_id if it is specified
    message_id: Int,
    /// If the message to be replied to is from a different chat, unique identifier for the chat or username of the channel (in the format `@channelusername`)
    chat_id: Option(IntOrString),
    /// Pass _True_ if the message should be sent even if the specified message to be replied to is not found; can be used only for replies in the same chat and forum topic.
    allow_sending_without_reply: Option(Bool),
    /// Quoted part of the message to be replied to; 0-1024 characters after entities parsing. The quote must be an exact substring of the message to be replied to, including _bold_, _italic_, _underline_, _strikethrough_, _spoiler_, and _custom_emoji_ entities. The message will fail to send if the quote isn't found in the original message.
    quote: Option(String),
    /// Mode for parsing entities in the quote. See [formatting options](https://core.telegram.org/bots/api#formatting-options) for more details.
    quote_parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in the quote. It can be specified instead of _quote_parse_mode_.
    quote_entities: Option(List(MessageEntity)),
    /// Position of the quote in the original message in UTF-16 code units
    quote_position: Option(Int),
  )
}

pub type ReplyMarkup {
  /// This object represents an inline keyboard that appears right next to the message it belongs to.
  /// **Official reference:** https://core.telegram.org/bots/api#inlinekeyboardmarkup
  InlineKeyboardMarkup(
    /// List of button rows, each represented by an List of [InlineKeyboardButton](https://core.telegram.org/bots/api#inlinekeyboardbutton) objects
    inline_keyboard: List(List(InlineKeyboardButton)),
  )
  /// This object represents a [custom keyboard](https://core.telegram.org/bots/features#keyboards) with reply options (see [Introduction to bots](https://core.telegram.org/bots/features#keyboards) for details and examples).
  ReplyKeyboardMarkup(
    /// Array of button rows, each represented by an Array of [KeyboardButton](https://core.telegram.org/bots/api#keyboardbutton) objects
    keyboard: List(List(Keyboard)),
    /// Requests clients to always show the keyboard when the regular keyboard is hidden. Defaults to _false_, in which case the custom keyboard can be hidden and opened with a keyboard icon.
    is_persistent: Option(Bool),
    /// Requests clients to resize the keyboard vertically for optimal fit (e.g., make the keyboard smaller if there are just two rows of buttons). Defaults to _false_, in which case the custom keyboard is always of the same height as the app's standard keyboard.
    resize_keyboard: Option(Bool),
    /// Requests clients to hide the keyboard as soon as it's been used. The keyboard will still be available, but clients will automatically display the usual letter-keyboard in the chat - the user can press a special button in the input field to see the custom keyboard again. Defaults to _false_.
    one_time_keyboard: Option(Bool),
    /// The placeholder to be shown in the input field when the keyboard is active; 1-64 characters
    input_field_placeholder: Option(String),
    /// Use this parameter if you want to show the keyboard to specific users only. Targets: 1) users that are @mentioned in the text of the [Message](https://core.telegram.org/bots/api#message) object; 2) if the bot's message is a reply to a message in the same chat and forum topic, sender of the original message.
    ///
    /// _Example_: A user requests to change the bot's language, bot replies to the request with a keyboard to select the new language. Other users in the group don't see the keyboard.
    selective: Option(Bool),
  )
  /// Upon receiving a message with this object, Telegram clients will remove the current custom keyboard and display the default letter-keyboard. By default, custom keyboards are displayed until a new keyboard is sent by a bot. An exception is made for one-time keyboards that are hidden immediately after the user presses a button (see [ReplyKeyboardMarkup](https://core.telegram.org/bots/api#replykeyboardmarkup)).
  ReplyKeyboardRemove(
    /// Requests clients to remove the custom keyboard (user will not be able to summon this keyboard; if you want to hide the keyboard from sight but keep it accessible, use _one_time_keyboard_ in [ReplyKeyboardMarkup](https://core.telegram.org/bots/api#replykeyboardmarkup))
    remove_keyboard: Bool,
    /// Use this parameter if you want to show the keyboard to specific users only. Targets: 1) users that are @mentioned in the text of the [Message](https://core.telegram.org/bots/api#message) object; 2) if the bot's message is a reply to a message in the same chat and forum topic, sender of the original message.
    ///
    /// _Example_: A user requests to change the bot's language, bot replies to the request with a keyboard to select the new language. Other users in the group don't see the keyboard.
    selective: Option(Bool),
  )
}

pub fn encode_reply_parameters(reply_parameters: ReplyParameters) -> Json {
  let message_id = [#("message_id", json.int(reply_parameters.message_id))]
  let chat_id =
    common.option_to_json_object_list(
      reply_parameters.chat_id,
      "chat_id",
      common.string_or_int_to_json,
    )
  let allow_sending_without_reply =
    common.option_to_json_object_list(
      reply_parameters.allow_sending_without_reply,
      "allow_sending_without_reply",
      json.bool,
    )
  let quote =
    common.option_to_json_object_list(
      reply_parameters.quote,
      "quote",
      json.string,
    )
  let quote_parse_mode =
    common.option_to_json_object_list(
      reply_parameters.quote_parse_mode,
      "quote_parse_mode",
      json.string,
    )
  let quote_entities =
    common.option_to_json_object_list(
      reply_parameters.quote_entities,
      "quote_entities",
      json.array(_, message_entity.encode),
    )
  let quote_position =
    common.option_to_json_object_list(
      reply_parameters.quote_position,
      "quote_position",
      json.int,
    )

  [
    message_id,
    chat_id,
    allow_sending_without_reply,
    quote,
    quote_parse_mode,
    quote_entities,
    quote_position,
  ]
  |> list.concat
  |> json.object
}
