import gleam/list
import gleam/json.{type Json}
import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import telega/models/common

pub type User {
  /// **Official reference:** https://core.telegram.org/bots/api#user
  User(
    /// Unique identifier for this user or bot.
    id: Int,
    is_bot: Bool,
    /// User's or bot's first name
    first_name: String,
    /// User's or bot's last name
    last_name: Option(String),
    /// Username, for private chats, supergroups and channels if available
    username: Option(String),
    /// [IETF language tag](https://en.wikipedia.org/wiki/IETF_language_tag) of the user's language
    language_code: Option(String),
    /// _True_, if this user is a Telegram Premium user
    is_premium: Option(Bool),
    /// _True_, if this user added the bot to the attachment menu
    added_to_attachment_menu: Option(Bool),
  )
}

pub fn decode(json: Dynamic) -> Result(User, dynamic.DecodeErrors) {
  json
  |> dynamic.decode8(
    User,
    dynamic.field("id", dynamic.int),
    dynamic.field("is_bot", dynamic.bool),
    dynamic.field("first_name", dynamic.string),
    dynamic.optional_field("last_name", dynamic.string),
    dynamic.optional_field("username", dynamic.string),
    dynamic.optional_field("language_code", dynamic.string),
    dynamic.optional_field("is_premium", dynamic.bool),
    dynamic.optional_field("added_to_attachment_menu", dynamic.bool),
  )
}

pub fn encode(user: User) -> Json {
  let id = [#("id", json.int(user.id))]
  let is_bot = [#("is_bot", json.bool(user.is_bot))]
  let first_name = [#("first_name", json.string(user.first_name))]
  let last_name =
    common.option_to_json_object_list(user.last_name, "last_name", json.string)
  let username =
    common.option_to_json_object_list(user.username, "username", json.string)
  let language_code =
    common.option_to_json_object_list(
      user.language_code,
      "language_code",
      json.string,
    )
  let is_premium =
    common.option_to_json_object_list(user.is_premium, "is_premium", json.bool)
  let added_to_attachment_menu =
    common.option_to_json_object_list(
      user.added_to_attachment_menu,
      "added_to_attachment_menu",
      json.bool,
    )

  [
    id,
    is_bot,
    first_name,
    last_name,
    username,
    language_code,
    is_premium,
    added_to_attachment_menu,
  ]
  |> list.concat
  |> json.object
}
