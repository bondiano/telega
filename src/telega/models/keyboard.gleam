import gleam/option.{type Option}
import gleam/dynamic.{type Dynamic}

pub type InlineKeyboardButton {
  // TODO: complete the implementation
  /// **Official reference:** https://core.telegram.org/bots/api#inlinekeyboardbutton
  InlineKeyboardButton(
    /// Label text on the button
    text: String,
    /// HTTP or `tg://` URL to be opened when the button is pressed. Links `tg://user?id=<user_id>` can be used to mention a user by their identifier without using a username, if this is allowed by their privacy settings.
    url: Option(String),
    /// Data to be sent in a [callback query](https://core.telegram.org/bots/api#callbackquery) to the bot when button is pressed, 1-64 bytes
    callback_data: Option(String),
    /// If set, pressing the button will prompt the user to select one of their chats, open that chat and insert the bot's username and the specified inline query in the input field. May be empty, in which case just the bot's username will be inserted.
    switch_inline_query: Option(String),
    /// set, pressing the button will insert the bot's username and the specified inline query in the current chat's input field. May be empty, in which case only the bot's username will be inserted.
    ///
    /// This offers a quick way for the user to open your bot in inline mode in the same chat - good for selecting something from multiple options.
    switch_inline_query_current_chat: Option(String),
    /// Specify True, to send a [Pay button](https://core.telegram.org/bots/api#payments).
    ///
    /// **NOTE**: This type of button **must** always be the first button in the first row and can only be used in invoice messages.
    pay: Option(Bool),
  )
}

pub type InlineKeyboardMarkup {
  /// **Official reference:** https://core.telegram.org/bots/api#inlinekeyboardmarkup
  InlineKeyboardMarkup(inline_keyboard: List(List(InlineKeyboardButton)))
}

// TODO: implement the following types
pub type Keyboard {
  Keyboard
}

pub fn decode_inline_button(
  json: Dynamic,
) -> Result(InlineKeyboardButton, dynamic.DecodeErrors) {
  json
  |> dynamic.decode6(
    InlineKeyboardButton,
    dynamic.field("text", dynamic.string),
    dynamic.optional_field("url", dynamic.string),
    dynamic.optional_field("callback_data", dynamic.string),
    dynamic.optional_field("switch_inline_query", dynamic.string),
    dynamic.optional_field("switch_inline_query_current_chat", dynamic.string),
    dynamic.optional_field("pay", dynamic.bool),
  )
}

pub fn decode_inline_markup(
  json: Dynamic,
) -> Result(InlineKeyboardMarkup, dynamic.DecodeErrors) {
  json
  |> dynamic.decode1(
    InlineKeyboardMarkup,
    dynamic.field(
      "inline_keyboard",
      dynamic.list(dynamic.list(decode_inline_button)),
    ),
  )
}
