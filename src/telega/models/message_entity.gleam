import gleam/json.{type Json}
import gleam/list
import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import telega/models/user.{type User}
import telega/models/common

pub type MessageEntity {
  /// **Official reference:** https://core.telegram.org/bots/api#messageentity
  MessageEntity(
    /// Type of the entity. Currently, can be "mention" (`@username`), "hashtag" (`#hashtag`), "cashtag" (`$USD`), "bot_command" (`/start@jobs_bot`), "url" (`https://telegram.org`), "email" (`do-not-reply@telegram.org`), "phone_number" (`+1-212-555-0123`), "bold" (**bold text**), "italic" (_italic text_), "underline" (underlined text), "strikethrough" (strikethrough text), "spoiler" (spoiler message), "blockquote" (block quotation), "code" (monowidth string), "pre" (monowidth block), "text_link" (for clickable text URLs), "text_mention" (for users [without usernames](https://telegram.org/blog/edit#new-mentions)), "custom_emoji" (for inline custom emoji stickers)
    entity_type: String,
    /// Offset in [UTF-16 code units](https://core.telegram.org/api/entities#entity-length) to the start of the entity
    offset: Int,
    /// Length of the entity in [UTF-16 code units](https://core.telegram.org/api/entities#entity-length)
    length: Int,
    /// For "text_link" only, URL that will be opened after user taps on the text
    url: Option(String),
    /// For "text_mention" only, the mentioned user
    user: Option(User),
    /// For "pre" only, the programming language of the entity text
    language: Option(String),
    /// For "custom_emoji" only, unique identifier of the custom emoji. Use [getCustomEmojiStickers](https://core.telegram.org/bots/api#getcustomemojistickers) to get full information about the sticker
    custom_emoji_id: Option(String),
  )
}

pub fn decode(json: Dynamic) -> Result(MessageEntity, dynamic.DecodeErrors) {
  json
  |> dynamic.decode7(
    MessageEntity,
    dynamic.field("type", dynamic.string),
    dynamic.field("offset", dynamic.int),
    dynamic.field("length", dynamic.int),
    dynamic.optional_field("url", dynamic.string),
    dynamic.optional_field("user", user.decode),
    dynamic.optional_field("language", dynamic.string),
    dynamic.optional_field("custom_emoji_id", dynamic.string),
  )
}

pub fn encode(message_entity: MessageEntity) -> Json {
  let entity_type = [#("entity_type", json.string(message_entity.entity_type))]
  let offset = [#("offset", json.int(message_entity.offset))]
  let length = [#("length", json.int(message_entity.length))]
  let url =
    common.option_to_json_object_list(message_entity.url, "url", json.string)
  let user =
    common.option_to_json_object_list(message_entity.user, "user", user.encode)
  let language =
    common.option_to_json_object_list(
      message_entity.language,
      "language",
      json.string,
    )
  let custom_emoji_id =
    common.option_to_json_object_list(
      message_entity.custom_emoji_id,
      "custom_emoji_id",
      json.string,
    )

  [entity_type, offset, length, url, user, language, custom_emoji_id]
  |> list.concat
  |> json.object
}
