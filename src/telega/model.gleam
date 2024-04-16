import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

// Reply ------------------------------------------------------------------------

// TODO: Support all the fields
pub type Update {
  /// **Official reference:** https://core.telegram.org/bots/api#update
  Update(
    /// The update's unique identifier. Update identifiers start from a certain positive number and increase sequentially.
    /// This identifier becomes especially handy if you're using webhooks, since it allows you to ignore repeated updates or to restore the correct update sequence, should they get out of order.
    /// If there are no new updates for at least a week, then identifier of the next update will be chosen randomly instead of sequentially.
    update_id: Int,
    /// New incoming message of any kind - text, photo, sticker, etc.
    message: Option(Message),
    /// New version of a message that is known to the bot and was edited.
    /// This update may at times be triggered by changes to message fields that are either unavailable or not actively used by your bot.
    edited_message: Option(Message),
    /// New incoming callback query
    callback_query: Option(CallbackQuery),
  )
}

/// Decode a message from the Telegram API.
pub fn decode_update(json: Dynamic) -> Result(Update, dynamic.DecodeErrors) {
  json
  |> dynamic.decode4(
    Update,
    dynamic.field("update_id", dynamic.int),
    dynamic.optional_field("message", decode_message),
    dynamic.optional_field("edited_message", decode_message),
    dynamic.optional_field("callback_query", decode_callback_query),
  )
}

// Chat ------------------------------------------------------------------------

pub type Chat {
  /// **Official reference:** https://core.telegram.org/bots/api#chat
  Chat(
    /// Unique identifier for this chat.
    id: Int,
    /// Username, for private chats, supergroups and channels if available
    username: Option(String),
    /// First name of the other party in a private chat
    first_name: Option(String),
    /// Last name of the other party in a private chat
    last_name: Option(String),
    /// True, if the supergroup chat is a forum (has [topics](https://telegram.org/blog/topics-in-groups-collectible-usernames#topics-in-groups) enabled)
    is_forum: Option(Bool),
  )
}

fn decode_chat(json: Dynamic) -> Result(Chat, dynamic.DecodeErrors) {
  json
  |> dynamic.decode5(
    Chat,
    dynamic.field("id", dynamic.int),
    dynamic.optional_field("username", dynamic.string),
    dynamic.optional_field("first_name", dynamic.string),
    dynamic.optional_field("last_name", dynamic.string),
    dynamic.optional_field("is_forum", dynamic.bool),
  )
}

// Message ------------------------------------------------------------------------

pub type Message {
  /// **Official reference:** https://core.telegram.org/bots/api#message
  Message(
    /// Unique message identifier inside this chat
    message_id: Int,
    /// Unique identifier of a message thread to which the message belongs; for supergroups only
    message_thread_id: Option(Int),
    /// Sender of the message; empty for messages sent to channels. For backward compatibility, the field contains a fake sender user in non-channel chats, if the message was sent on behalf of a chat.
    from: Option(User),
    /// Sender of the message, sent on behalf of a chat. For example, the channel itself for channel posts, the supergroup itself for messages from anonymous group administrators, the linked channel for messages automatically forwarded to the discussion group. For backward compatibility, the field _from_ contains a fake sender user in non-channel chats, if the message was sent on behalf of a chat.
    sender_chat: Option(Chat),
    /// If the sender of the message boosted the chat, the number of boosts added by the user
    sender_boost_count: Option(Int),
    /// Date the message was sent in Unix time. It is always a positive number, representing a valid date.
    date: Int,
    /// Chat the message belongs to
    chat: Chat,
    // TODO: forward_origin
    /// _True_, if the message is sent to a forum topic
    is_topic_message: Option(Bool),
    /// _True_, if the message is a channel post that was automatically forwarded to the connected discussion group
    is_automatic_forward: Option(Bool),
    /// For replies in the same chat and message thread, the original message. Note that the Message object in this field will not contain further _reply_to_message_ fields even if it itself is a reply.
    reply_to_message: Option(Message),
    // TODO: external_reply
    // TODO: quote
    // TODO: reply_to_story
    via_bot: Option(User),
    /// Date the message was last edited in Unix time
    edit_date: Option(Int),
    /// _True_, if the message can't be forwarded
    has_protected_content: Option(Bool),
    /// _True_, if the message was sent by an implicit action, for example, as an away or a greeting business message, or as a scheduled message
    is_from_offline: Option(Bool),
    /// The unique identifier of a media message group this message belongs to
    media_group_id: Option(String),
    /// Signature of the post author for messages in channels, or the custom title of an anonymous group administrator
    author_signature: Option(String),
    /// For text messages, the actual UTF-8 text of the message
    text: Option(String),
    /// For text messages, special entities like usernames, URLs, bot commands, etc. that appear in the text
    entities: Option(List(MessageEntity)),
    // TODO: link_preview_options
    // TOOD: animation
    // TODO: audio
    // TODO: document
    // TODO: photo
    // TODO: sticker
    // TODO: story
    // TODO: video
    // TODO: video_note
    // TODO: voice
    // Caption for the animation, audio, document, photo, video or voice
    caption: Option(String),
    /// For messages with a caption, special entities like usernames, URLs, bot commands, etc. that appear in the caption
    caption_entities: Option(List(MessageEntity)),
    /// _True_, if the message media is covered by a spoiler animation
    has_media_spoiler: Option(Bool),
    // TODO: contact
    // TODO: dice
    // TODO: game
    // TODO: poll
    // TODO: venue
    // TODO: location
    /// New members that were added to the group or supergroup and information about them (the bot itself may be one of these members)
    new_chat_members: Option(List(User)),
    /// A member was removed from the group, information about them (this member may be the bot itself)
    left_chat_member: Option(User),
    /// A chat title was changed to this value
    new_chat_title: Option(String),
    // TODO: new_chat_photo
    /// Service message: the chat photo was deleted
    delete_chat_photo: Option(Bool),
    /// Service message: the group has been created
    group_chat_created: Option(Bool),
    /// Service message: the supergroup has been created. This field can't be received in a message coming through updates, because bot can't be a member of a supergroup when it is created. It can only be found in reply_to_message if someone replies to a very first message in a directly created supergroup.
    supergroup_chat_created: Option(Bool),
    /// Service message: the channel has been created. This field can't be received in a message coming through updates, because bot can't be a member of a channel when it is created. It can only be found in reply_to_message if someone replies to a very first message in a channel.
    channel_chat_created: Option(Bool),
    // TODO: message_auto_delete_timer_changed
    /// The group has been migrated to a supergroup with the specified identifier.
    migrate_to_chat_id: Option(Int),
    /// The supergroup has been migrated from a group with the specified identifier.
    migrate_from_chat_id: Option(Int),
    // TODO: pinned_message
    // TODO: invoice
    // TODO: successful_payment
    // TODO: users_shared
    // TODO: chat_shared
    /// The domain name of the website on which the user has logged in. [More about Telegram Login >>](https://core.telegram.org/widgets/login)
    connected_website: Option(String),
    // TODO: write_access_allowed
    // TODO: passport_data
    // TODO: proximity_alert_triggered
    // TODO: boost_added
    // TODO: forum_topic_created
    // TODO: forum_topic_edited
    // TODO: forum_topic_closed
    // TODO: forum_topic_reopened
    // TODO: general_forum_topic_hidden
    // TODO: general_forum_topic_unhidden
    // TODO: giveaway_created
    // TODO: giveaway
    // TODO: giveaway_winners
    // TODO: giveaway_completed
    // TODO: video_chat_scheduled
    // TODO: video_chat_started
    // TODO: video_chat_ended
    // TODO: video_chat_participants_invited
    web_app_data: Option(WebAppData),
    /// Inline keyboard attached to the message. `login_url` buttons are represented as ordinary `url` buttons.
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

pub fn decode_message(json: Dynamic) -> Result(Message, dynamic.DecodeErrors) {
  let decode_message_id = dynamic.field("message_id", dynamic.int)
  let decode_message_thread_id =
    dynamic.optional_field("message_thread_id", dynamic.int)
  let decode_from = dynamic.optional_field("from", decode_user)
  let decode_sender_chat = dynamic.optional_field("sender_chat", decode_chat)
  let decode_sender_boost_count =
    dynamic.optional_field("sender_boost_count", dynamic.int)
  let decode_date = dynamic.field("date", dynamic.int)
  let decode_chat = dynamic.field("chat", decode_chat)
  let decode_is_topic_message =
    dynamic.optional_field("is_topic_message", dynamic.bool)
  let decode_is_automatic_forward =
    dynamic.optional_field("is_automatic_forward", dynamic.bool)
  let decode_reply_to_message =
    dynamic.optional_field("reply_to_message", decode_message)
  let decode_via_bot = dynamic.optional_field("via_bot", decode_user)
  let decode_edit_date = dynamic.optional_field("edit_date", dynamic.int)
  let decode_has_protected_content =
    dynamic.optional_field("has_protected_content", dynamic.bool)
  let decode_media_group_id =
    dynamic.optional_field("media_group_id", dynamic.string)
  let decode_author_signature =
    dynamic.optional_field("author_signature", dynamic.string)
  let decode_text = dynamic.optional_field("text", dynamic.string)
  let decode_entities =
    dynamic.optional_field("entities", dynamic.list(decode_message_entity))
  let decode_caption = dynamic.optional_field("caption", dynamic.string)
  let decode_caption_entities =
    dynamic.optional_field(
      "caption_entities",
      dynamic.list(decode_message_entity),
    )
  let decode_has_media_spoiler =
    dynamic.optional_field("has_media_spoiler", dynamic.bool)
  let decode_new_chat_members =
    dynamic.optional_field("new_chat_members", dynamic.list(decode_user))
  let decode_left_chat_member =
    dynamic.optional_field("left_chat_member", decode_user)
  let decode_new_chat_title =
    dynamic.optional_field("new_chat_title", dynamic.string)
  let decode_delete_chat_photo =
    dynamic.optional_field("delete_chat_photo", dynamic.bool)
  let decode_group_chat_created =
    dynamic.optional_field("group_chat_created", dynamic.bool)
  let decode_supergroup_chat_created =
    dynamic.optional_field("supergroup_chat_created", dynamic.bool)
  let decode_channel_chat_created =
    dynamic.optional_field("channel_chat_created", dynamic.bool)
  let decode_migrate_to_chat_id =
    dynamic.optional_field("migrate_to_chat_id", dynamic.int)
  let decode_migrate_from_chat_id =
    dynamic.optional_field("migrate_from_chat_id", dynamic.int)
  let decode_connected_website =
    dynamic.optional_field("connected_website", dynamic.string)
  let decode_inline_keyboard_markup =
    dynamic.optional_field("reply_markup", decode_inline_markup)
  let decode_web_app_data =
    dynamic.optional_field("web_app_data", decode_web_app_data)
  let decode_is_from_offline =
    dynamic.optional_field("is_from_offline", dynamic.bool)

  case
    decode_message_id(json),
    decode_message_thread_id(json),
    decode_from(json),
    decode_sender_chat(json),
    decode_sender_boost_count(json),
    decode_date(json),
    decode_chat(json),
    decode_is_topic_message(json),
    decode_is_automatic_forward(json),
    decode_reply_to_message(json),
    decode_via_bot(json),
    decode_edit_date(json),
    decode_has_protected_content(json),
    decode_media_group_id(json),
    decode_author_signature(json),
    decode_text(json),
    decode_entities(json),
    decode_caption(json),
    decode_caption_entities(json),
    decode_has_media_spoiler(json),
    decode_new_chat_members(json),
    decode_left_chat_member(json),
    decode_new_chat_title(json),
    decode_delete_chat_photo(json),
    decode_group_chat_created(json),
    decode_supergroup_chat_created(json),
    decode_channel_chat_created(json),
    decode_migrate_to_chat_id(json),
    decode_migrate_from_chat_id(json),
    decode_connected_website(json),
    decode_inline_keyboard_markup(json),
    decode_web_app_data(json),
    decode_is_from_offline(json)
  {
    Ok(message_id),
      Ok(message_thread_id),
      Ok(from),
      Ok(sender_chat),
      Ok(sender_boost_count),
      Ok(date),
      Ok(chat),
      Ok(is_topic_message),
      Ok(is_automatic_forward),
      Ok(reply_to_message),
      Ok(via_bot),
      Ok(edit_date),
      Ok(has_protected_content),
      Ok(media_group_id),
      Ok(author_signature),
      Ok(text),
      Ok(entities),
      Ok(caption),
      Ok(caption_entities),
      Ok(has_media_spoiler),
      Ok(new_chat_members),
      Ok(left_chat_member),
      Ok(new_chat_title),
      Ok(delete_chat_photo),
      Ok(group_chat_created),
      Ok(supergroup_chat_created),
      Ok(channel_chat_created),
      Ok(migrate_to_chat_id),
      Ok(migrate_from_chat_id),
      Ok(connected_website),
      Ok(inline_keyboard_markup),
      Ok(web_app_data),
      Ok(is_from_offline)
    ->
      Ok(Message(
        message_id: message_id,
        message_thread_id: message_thread_id,
        from: from,
        sender_chat: sender_chat,
        sender_boost_count: sender_boost_count,
        date: date,
        chat: chat,
        is_topic_message: is_topic_message,
        is_automatic_forward: is_automatic_forward,
        reply_to_message: reply_to_message,
        via_bot: via_bot,
        edit_date: edit_date,
        has_protected_content: has_protected_content,
        is_from_offline: is_from_offline,
        media_group_id: media_group_id,
        author_signature: author_signature,
        text: text,
        entities: entities,
        caption: caption,
        caption_entities: caption_entities,
        has_media_spoiler: has_media_spoiler,
        new_chat_members: new_chat_members,
        left_chat_member: left_chat_member,
        new_chat_title: new_chat_title,
        delete_chat_photo: delete_chat_photo,
        group_chat_created: group_chat_created,
        supergroup_chat_created: supergroup_chat_created,
        channel_chat_created: channel_chat_created,
        migrate_to_chat_id: migrate_to_chat_id,
        migrate_from_chat_id: migrate_from_chat_id,
        connected_website: connected_website,
        web_app_data: web_app_data,
        reply_markup: inline_keyboard_markup,
      ))
    message_id,
      message_thread_id,
      from,
      sender_chat,
      sender_boost_count,
      date,
      chat,
      is_topic_message,
      is_automatic_forward,
      reply_to_message,
      via_bot,
      edit_date,
      has_protected_content,
      media_group_id,
      author_signature,
      text,
      entities,
      caption,
      caption_entities,
      has_media_spoiler,
      new_chat_members,
      left_chat_member,
      new_chat_title,
      delete_chat_photo,
      group_chat_created,
      supergroup_chat_created,
      channel_chat_created,
      migrate_to_chat_id,
      migrate_from_chat_id,
      connected_website,
      inline_keyboard_markup,
      web_app_data,
      is_from_offline ->
      Error(
        list.concat([
          all_errors(message_id),
          all_errors(message_thread_id),
          all_errors(from),
          all_errors(sender_chat),
          all_errors(sender_boost_count),
          all_errors(date),
          all_errors(chat),
          all_errors(is_topic_message),
          all_errors(is_automatic_forward),
          all_errors(reply_to_message),
          all_errors(via_bot),
          all_errors(edit_date),
          all_errors(has_protected_content),
          all_errors(is_from_offline),
          all_errors(media_group_id),
          all_errors(author_signature),
          all_errors(text),
          all_errors(entities),
          all_errors(caption),
          all_errors(caption_entities),
          all_errors(has_media_spoiler),
          all_errors(new_chat_members),
          all_errors(left_chat_member),
          all_errors(new_chat_title),
          all_errors(delete_chat_photo),
          all_errors(group_chat_created),
          all_errors(supergroup_chat_created),
          all_errors(channel_chat_created),
          all_errors(migrate_to_chat_id),
          all_errors(migrate_from_chat_id),
          all_errors(connected_website),
          all_errors(inline_keyboard_markup),
          all_errors(web_app_data),
        ]),
      )
  }
}

// BotCommand ---------------------------------------------------------------------

pub type BotCommand {
  /// **Official reference:** https://core.telegram.org/bots/api#botcommand
  BotCommand(
    /// Text of the command; 1-32 characters. Can contain only lowercase English letters, digits and underscores.
    command: String,
    /// Description of the command; 1-256 characters.
    description: String,
  )
}

/// **Official reference:** https://core.telegram.org/bots/api#botcommandscope
pub type BotCommandScope {
  /// Represents the default scope of bot commands. Default commands are used if no commands with a narrower scope are specified for the user.
  BotCommandDefaultScope
  /// Represents the scope of bot commands, covering all private chats.
  BotCommandAllPrivateChatsScope
  /// Represents the scope of bot commands, covering all group and supergroup chats.
  BotCommandScopeAllGroupChats
  /// Represents the scope of bot commands, covering all group and supergroup chat administrators.
  BotCommandScopeAllChatAdministrators
  /// Represents the scope of bot commands, covering a specific chat.
  BotCommandScopeChat(
    /// Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
    chat_id: Int,
  )
  /// Represents the scope of bot commands, covering a specific chat.
  BotCommandScopeChatString(
    /// Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
    chat_id: IntOrString,
  )
  /// Represents the scope of bot commands, covering all administrators of a specific group or supergroup chat.
  BotCommandScopeChatAdministrators(
    /// Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
    chat_id: IntOrString,
  )
  /// Represents the scope of bot commands, covering a specific member of a group or supergroup chat.
  BotCommandScopeChatMember(
    /// Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
    chat_id: IntOrString,
    /// Unique identifier of the target user
    user_id: Int,
  )
}

pub fn decode_bot_command(
  json: Dynamic,
) -> Result(List(BotCommand), dynamic.DecodeErrors) {
  json
  |> dynamic.list(dynamic.decode2(
    BotCommand,
    dynamic.field("command", dynamic.string),
    dynamic.field("description", dynamic.string),
  ))
}

// BotCommandParameters ---------------------------------------------------------------------

pub type BotCommandParameters {
  BotCommandParameters(
    /// An object, describing scope of users for which the commands are relevant. Defaults to `BotCommandScopeDefault`.
    scope: Option(BotCommandScope),
    /// A two-letter ISO 639-1 language code. If empty, commands will be applied to all users from the given scope, for whose language there are no dedicated commands
    language_code: Option(String),
  )
}

pub fn default_botcommand_parameters() -> BotCommandParameters {
  BotCommandParameters(scope: None, language_code: None)
}

pub fn encode_botcommand_parameters(
  params: BotCommandParameters,
) -> List(#(String, Json)) {
  [
    #("scope", json.nullable(params.scope, bot_command_scope_to_json)),
    #("language_code", json.nullable(params.language_code, json.string)),
  ]
}

pub fn bot_command_scope_to_json(scope: BotCommandScope) {
  case scope {
    BotCommandDefaultScope ->
      json_object_filter_nulls([#("type", json.string("default"))])
    BotCommandAllPrivateChatsScope ->
      json_object_filter_nulls([#("type", json.string("all_private_chats"))])
    BotCommandScopeAllGroupChats ->
      json_object_filter_nulls([#("type", json.string("all_group_chats"))])
    BotCommandScopeAllChatAdministrators ->
      json_object_filter_nulls([
        #("type", json.string("all_chat_administrators")),
      ])
    BotCommandScopeChat(chat_id: chat_id) ->
      json_object_filter_nulls([
        #("type", json.string("chat")),
        #("chat_id", json.int(chat_id)),
      ])
    BotCommandScopeChatString(chat_id: chat_id) ->
      json_object_filter_nulls([
        #("type", json.string("chat")),
        #("chat_id", encode_int_or_string(chat_id)),
      ])
    BotCommandScopeChatAdministrators(chat_id: chat_id) ->
      json_object_filter_nulls([
        #("type", json.string("chat_administrators")),
        #("chat_id", encode_int_or_string(chat_id)),
      ])
    BotCommandScopeChatMember(chat_id: chat_id, user_id: user_id) ->
      json_object_filter_nulls([
        #("type", json.string("chat_member")),
        #("chat_id", encode_int_or_string(chat_id)),
        #("user_id", json.int(user_id)),
      ])
  }
}

pub fn bot_commands_from(commands: List(#(String, String))) -> List(BotCommand) {
  commands
  |> list.map(fn(command) {
    let #(command, description) = command
    BotCommand(command: command, description: description)
  })
}

// User ---------------------------------------------------------------------

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

pub fn decode_user(json: Dynamic) -> Result(User, dynamic.DecodeErrors) {
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

pub fn encode_user(user: User) -> Json {
  let id = #("id", json.int(user.id))
  let is_bot = #("is_bot", json.bool(user.is_bot))
  let first_name = #("first_name", json.string(user.first_name))
  let last_name = #("last_name", json.nullable(user.last_name, json.string))
  let username = #("username", json.nullable(user.username, json.string))
  let language_code = #(
    "language_code",
    json.nullable(user.language_code, json.string),
  )
  let is_premium = #("is_premium", json.nullable(user.is_premium, json.bool))
  let added_to_attachment_menu = #(
    "added_to_attachment_menu",
    json.nullable(user.added_to_attachment_menu, json.bool),
  )

  json_object_filter_nulls([
    id,
    is_bot,
    first_name,
    last_name,
    username,
    language_code,
    is_premium,
    added_to_attachment_menu,
  ])
}

// MessageEntity ---------------------------------------------------------------------

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

pub fn decode_message_entity(
  json: Dynamic,
) -> Result(MessageEntity, dynamic.DecodeErrors) {
  json
  |> dynamic.decode7(
    MessageEntity,
    dynamic.field("type", dynamic.string),
    dynamic.field("offset", dynamic.int),
    dynamic.field("length", dynamic.int),
    dynamic.optional_field("url", dynamic.string),
    dynamic.optional_field("user", decode_user),
    dynamic.optional_field("language", dynamic.string),
    dynamic.optional_field("custom_emoji_id", dynamic.string),
  )
}

pub fn encode_message_entity(message_entity: MessageEntity) -> Json {
  let entity_type = #("entity_type", json.string(message_entity.entity_type))
  let offset = #("offset", json.int(message_entity.offset))
  let length = #("length", json.int(message_entity.length))
  let url = #("url", json.nullable(message_entity.url, json.string))
  let user = #("user", json.nullable(message_entity.user, encode_user))
  let language = #(
    "language",
    json.nullable(message_entity.language, json.string),
  )
  let custom_emoji_id = #(
    "custom_emoji_id",
    json.nullable(message_entity.custom_emoji_id, json.string),
  )

  json_object_filter_nulls([
    entity_type,
    offset,
    length,
    url,
    user,
    language,
    custom_emoji_id,
  ])
}

// SendMessage ------------------------------------------------------------------------

pub type SendMessageParameters {
  /// Parameters to send using the [sendMessage](https://core.telegram.org/bots/api#sendmessage) method
  SendMessageParameters(
    /// Unique identifier of the business connection on behalf of which the message will be sent
    business_connection_id: Option(String),
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
    message_thread_id: Option(Int),
    /// Text of the message to be sent, 1-4096 characters after entities parsing
    text: String,
    /// Mode for parsing entities in the message text. See [formatting options](https://core.telegram.org/bots/api#formatting-options) for more details.
    parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in message text, which can be specified instead of _parse_mode_
    entities: Option(List(MessageEntity)),
    /// Link preview generation options for the message
    link_preview_options: Option(LinkPreviewOptions),
    /// Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
    disable_notification: Option(Bool),
    /// Protects the contents of the sent message from forwarding and saving
    protect_content: Option(Bool),
    /// Description of the message to reply to
    reply_parameters: Option(ReplyParameters),
    /// Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots/features#inline-keyboards), [custom reply keyboard](https://core.telegram.org/bots/features#keyboards), instructions to remove a reply keyboard or to force a reply from the user. Not supported for messages sent on behalf of a business account
    reply_markup: Option(ReplyMarkup),
  )
}

pub fn new_send_message_parameters(
  chat_id chat_id: IntOrString,
  text text: String,
) -> SendMessageParameters {
  SendMessageParameters(
    chat_id: chat_id,
    text: text,
    business_connection_id: None,
    message_thread_id: None,
    parse_mode: None,
    entities: None,
    link_preview_options: None,
    disable_notification: None,
    protect_content: None,
    reply_parameters: None,
    reply_markup: None,
  )
}

pub fn set_send_message_parameters_reply_markup(
  params: SendMessageParameters,
  reply_markup: ReplyMarkup,
) -> SendMessageParameters {
  SendMessageParameters(..params, reply_markup: Some(reply_markup))
}

pub fn encode_send_message_parameters(
  send_message_parameters: SendMessageParameters,
) -> Json {
  let business_connection_id = #(
    "business_connection_id",
    json.nullable(send_message_parameters.business_connection_id, json.string),
  )
  let chat_id = #(
    "chat_id",
    encode_int_or_string(send_message_parameters.chat_id),
  )

  let message_thread_id = #(
    "message_thread_id",
    json.nullable(send_message_parameters.message_thread_id, json.int),
  )
  let text = #("text", json.string(send_message_parameters.text))
  let parse_mode = #(
    "parse_mode",
    json.nullable(send_message_parameters.parse_mode, json.string),
  )
  let entities = #(
    "entities",
    json.nullable(send_message_parameters.entities, json.array(
      _,
      encode_message_entity,
    )),
  )
  let link_preview_options = #(
    "link_preview_options",
    json.nullable(
      send_message_parameters.link_preview_options,
      encode_link_preview_options,
    ),
  )
  let disable_notification = #(
    "disable_notification",
    json.nullable(send_message_parameters.disable_notification, json.bool),
  )
  let protect_content = #(
    "protect_content",
    json.nullable(send_message_parameters.protect_content, json.bool),
  )
  let reply_parameters = #(
    "reply_parameters",
    json.nullable(
      send_message_parameters.reply_parameters,
      encode_reply_parameters,
    ),
  )
  let reply_markup = #(
    "reply_markup",
    json.nullable(send_message_parameters.reply_markup, encode_reply_markup),
  )

  json_object_filter_nulls([
    business_connection_id,
    chat_id,
    message_thread_id,
    text,
    parse_mode,
    entities,
    link_preview_options,
    disable_notification,
    protect_content,
    reply_parameters,
    reply_markup,
  ])
}

// InlineKeyboard ---------------------------------------------------------------------

pub type InlineKeyboardButton {
  /// **Official reference:** https://core.telegram.org/bots/api#inlinekeyboardbutton
  InlineKeyboardButton(
    /// Label text on the button
    text: String,
    /// HTTP or `tg://` URL to be opened when the button is pressed. Links `tg://user?id=<user_id>` can be used to mention a user by their identifier without using a username, if this is allowed by their privacy settings.
    url: Option(String),
    /// Data to be sent in a [callback query](https://core.telegram.org/bots/api#callbackquery) to the bot when button is pressed, 1-64 bytes
    callback_data: Option(String),
    /// Description of the [Web App](https://core.telegram.org/bots/webapps) that will be launched when the user presses the button. The Web App will be able to send an arbitrary message on behalf of the user using the method [answerWebAppQuery](https://core.telegram.org/bots/api#answerwebappquery). Available only in private chats between a user and the bot.
    web_app: Option(WebAppInfo),
    /// An HTTPS URL used to automatically authorize the user. Can be used as a replacement for the [Telegram Login Widget](https://core.telegram.org/widgets/login).
    login_url: Option(LoginUrl),
    /// If set, pressing the button will prompt the user to select one of their chats, open that chat and insert the bot's username and the specified inline query in the input field. May be empty, in which case just the bot's username will be inserted.
    switch_inline_query: Option(String),
    /// set, pressing the button will insert the bot's username and the specified inline query in the current chat's input field. May be empty, in which case only the bot's username will be inserted.
    ///
    /// This offers a quick way for the user to open your bot in inline mode in the same chat - good for selecting something from multiple options.
    switch_inline_query_current_chat: Option(String),
    /// If set, pressing the button will prompt the user to select one of their chats of the specified type, open that chat and insert the bot's username and the specified inline query in the input field
    switch_inline_query_chosen_chat: Option(SwitchInlineQueryChosenChat),
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

pub fn encode_inline_keyboard_button(
  inline_keyboard_button: InlineKeyboardButton,
) -> Json {
  let text = #("text", json.string(inline_keyboard_button.text))
  let url = #("url", json.nullable(inline_keyboard_button.url, json.string))
  let callback_data = #(
    "callback_data",
    json.nullable(inline_keyboard_button.callback_data, json.string),
  )
  let web_app = #(
    "web_app",
    json.nullable(inline_keyboard_button.web_app, encode_web_app_info),
  )
  let login_url = #(
    "login_url",
    json.nullable(inline_keyboard_button.login_url, encode_login_url),
  )
  let switch_inline_query = #(
    "switch_inline_query",
    json.nullable(inline_keyboard_button.switch_inline_query, json.string),
  )
  let switch_inline_query_current_chat = #(
    "switch_inline_query_current_chat",
    json.nullable(
      inline_keyboard_button.switch_inline_query_current_chat,
      json.string,
    ),
  )
  let switch_inline_query_chosen_chat = #(
    "switch_inline_query_chosen_chat",
    json.nullable(
      inline_keyboard_button.switch_inline_query_chosen_chat,
      encode_switch_inline_query_chosen_chat,
    ),
  )
  let pay = #("pay", json.nullable(inline_keyboard_button.pay, json.bool))

  json_object_filter_nulls([
    text,
    url,
    callback_data,
    web_app,
    login_url,
    switch_inline_query,
    switch_inline_query_current_chat,
    switch_inline_query_chosen_chat,
    pay,
  ])
}

pub fn decode_inline_button(
  json: Dynamic,
) -> Result(InlineKeyboardButton, dynamic.DecodeErrors) {
  json
  |> dynamic.decode9(
    InlineKeyboardButton,
    dynamic.field("text", dynamic.string),
    dynamic.optional_field("url", dynamic.string),
    dynamic.optional_field("callback_data", dynamic.string),
    dynamic.optional_field("web_app", decode_web_app_info),
    dynamic.optional_field("login_url", decode_login_url),
    dynamic.optional_field("switch_inline_query", dynamic.string),
    dynamic.optional_field("switch_inline_query_current_chat", dynamic.string),
    dynamic.optional_field(
      "switch_inline_query_chosen_chat",
      decode_switch_inline_query_chosen_chat,
    ),
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

pub fn encode_inline_keyboard_markup(
  inline_keyboard_markup: InlineKeyboardMarkup,
) -> Json {
  let inline_keyboard = #(
    "inline_keyboard",
    json.array(inline_keyboard_markup.inline_keyboard, json.array(
      _,
      encode_inline_keyboard_button,
    )),
  )

  json_object_filter_nulls([inline_keyboard])
}

// Keyboard ---------------------------------------------------------------------

pub type KeyboardButton {
  /// This object represents one button of the reply keyboard. For simple text buttons, String can be used instead of this object to specify the button text. The optional fields _web_app_, _request_users_, _request_chat_, _request_contact_, _request_location_, and _request_poll_ are mutually exclusive.
  ///
  /// **Official reference:** https://core.telegram.org/bots/api#keyboardbutton
  KeyboardButton(
    /// Text of the button. If none of the optional fields are used, it will be sent as a message when the button is pressed
    text: String,
    /// If specified, pressing the button will open a list of suitable users. Identifiers of selected users will be sent to the bot in a “users_shared” service message. Available in private chats only.
    request_users: Option(KeyboardButtonRequestUsers),
    /// If specified, pressing the button will open a list of suitable chats. Tapping on a chat will send its identifier to the bot in a “chat_shared” service message. Available in private chats only.
    request_chat: Option(KeyboardButtonRequestChat),
    /// If _True_, the user's phone number will be sent as a contact when the button is pressed. Available in private chats only.
    request_contact: Option(Bool),
    /// If _True_, the user's current location will be sent when the button is pressed. Available in private chats only.
    request_location: Option(Bool),
    /// If specified, the user will be asked to create a poll and send it to the bot when the button is pressed. Available in private chats only.
    request_poll: Option(KeyboardButtonPollType),
    /// If specified, the described [Web App](https://core.telegram.org/bots/webapps) will be launched when the button is pressed. The Web App will be able to send a “web_app_data” service message. Available in private chats only.
    web_app: Option(WebAppInfo),
  )
}

pub fn encode_keyboard_button(keyboard_button: KeyboardButton) -> Json {
  let text = #("text", json.string(keyboard_button.text))
  let request_users = #(
    "request_users",
    json.nullable(
      keyboard_button.request_users,
      encode_keyboard_button_request_users,
    ),
  )
  let request_chat = #(
    "request_chat",
    json.nullable(
      keyboard_button.request_chat,
      encode_keyboard_button_request_chat,
    ),
  )
  let request_contact = #(
    "request_contact",
    json.nullable(keyboard_button.request_contact, json.bool),
  )
  let request_location = #(
    "request_location",
    json.nullable(keyboard_button.request_location, json.bool),
  )
  let request_poll = #(
    "request_poll",
    json.nullable(
      keyboard_button.request_poll,
      encode_keyboard_button_poll_type,
    ),
  )
  let web_app = #(
    "web_app",
    json.nullable(keyboard_button.web_app, encode_web_app_info),
  )

  json_object_filter_nulls([
    text,
    request_users,
    request_chat,
    request_contact,
    request_location,
    request_poll,
    web_app,
  ])
}

pub type KeyboardButtonRequestUsers {
  /// This object defines the criteria used to request suitable users. Information about the selected users will be shared with the bot when the corresponding button is pressed.
  ///
  /// [More about requesting users](https://core.telegram.org/bots/features#chat-and-user-selection).
  ///
  /// **Official reference:** https://core.telegram.org/bots/api#keyboardbuttonrequestusers
  KeyboardButtonRequestUsers(
    /// Signed 32-bit identifier of the request that will be received back in the [UsersShared](https://core.telegram.org/bots/api#usersshared) object. Must be unique within the message
    request_id: Int,
    /// Pass _True_ to request bots, pass _False_ to request regular users. If not specified, no additional restrictions are applied.
    user_is_bot: Option(Bool),
    /// Pass _True_ to request premium users, pass _False_ to request non-premium users. If not specified, no additional restrictions are applied.
    user_is_premium: Option(Bool),
    /// The maximum number of users to be selected; 1-10. Defaults to 1.
    max_quantity: Option(Int),
    /// Pass _True_ to request the users' first and last name
    request_name: Option(Bool),
    /// Pass _True_ to request the users' username
    request_username: Option(Bool),
    /// Pass _True_ to request the users' photo
    request_photo: Option(Bool),
  )
}

pub fn encode_keyboard_button_request_users(
  keyboard_button_request_users: KeyboardButtonRequestUsers,
) -> Json {
  let request_id = #(
    "request_id",
    json.int(keyboard_button_request_users.request_id),
  )
  let user_is_bot = #(
    "user_is_bot",
    json.nullable(keyboard_button_request_users.user_is_bot, json.bool),
  )
  let user_is_premium = #(
    "user_is_premium",
    json.nullable(keyboard_button_request_users.user_is_premium, json.bool),
  )
  let max_quantity = #(
    "max_quantity",
    json.nullable(keyboard_button_request_users.max_quantity, json.int),
  )
  let request_name = #(
    "request_name",
    json.nullable(keyboard_button_request_users.request_name, json.bool),
  )
  let request_username = #(
    "request_username",
    json.nullable(keyboard_button_request_users.request_username, json.bool),
  )
  let request_photo = #(
    "request_photo",
    json.nullable(keyboard_button_request_users.request_photo, json.bool),
  )

  json_object_filter_nulls([
    request_id,
    user_is_bot,
    user_is_premium,
    max_quantity,
    request_name,
    request_username,
    request_photo,
  ])
}

pub fn decode_keyboard_button_request_users(
  json: Dynamic,
) -> Result(KeyboardButtonRequestUsers, dynamic.DecodeErrors) {
  json
  |> dynamic.decode7(
    KeyboardButtonRequestUsers,
    dynamic.field("request_id", dynamic.int),
    dynamic.optional_field("user_is_bot", dynamic.bool),
    dynamic.optional_field("user_is_premium", dynamic.bool),
    dynamic.optional_field("max_quantity", dynamic.int),
    dynamic.optional_field("request_name", dynamic.bool),
    dynamic.optional_field("request_username", dynamic.bool),
    dynamic.optional_field("request_photo", dynamic.bool),
  )
}

pub type KeyboardButtonRequestChat {
  /// This object defines the criteria used to request a suitable chat. Information about the selected chat will be shared with the bot when the corresponding button is pressed. The bot will be granted requested rights in the сhat if appropriate
  ///
  /// [More about requesting chats](https://core.telegram.org/bots/features#chat-and-user-selection).
  ///
  /// **Official reference:** https://core.telegram.org/bots/api#keyboardbuttonrequestchat
  KeyboardButtonRequestChat(
    /// Signed 32-bit identifier of the request, which will be received back in the [ChatShared](https://core.telegram.org/bots/api#chatshared) object. Must be unique within the message
    request_id: Int,
    /// Pass _True_ to request a channel chat, pass _False_ to request a group or a supergroup chat.
    chat_is_channel: Bool,
    /// Pass _True_ to request a forum supergroup, pass _False_ to request a non-forum chat. If not specified, no additional restrictions are applied.
    chat_is_forum: Option(Bool),
    /// Pass _True_ to request a supergroup or a channel with a username, pass _False_ to request a chat without a username. If not specified, no additional restrictions are applied.
    chat_has_username: Option(Bool),
    /// Pass _True_ to request a chat owned by the user. Otherwise, no additional restrictions are applied.
    chat_is_created: Option(Bool),
    /// A JSON-serialized object listing the required administrator rights of the user in the chat. The rights must be a superset of _bot_administrator_rights_. If not specified, no additional restrictions are applied.
    user_administrator_rights: Option(ChatAdministratorRights),
    /// A JSON-serialized object listing the required administrator rights of the bot in the chat. The rights must be a subset of _user_administrator_rights_. If not specified, no additional restrictions are applied.
    bot_administrator_rights: Option(ChatAdministratorRights),
    /// Pass _True_ to request a chat with the bot as a member. Otherwise, no additional restrictions are applied.
    bot_is_member: Option(Bool),
    /// Pass _True_ to request the chat's title
    request_title: Option(Bool),
    /// Pass _True_ to request the chat's username
    request_username: Option(Bool),
    /// Pass _True_ to request the chat's photo
    request_photo: Option(Bool),
  )
}

pub fn encode_keyboard_button_request_chat(
  keyboard_button_request_chat: KeyboardButtonRequestChat,
) -> Json {
  let request_id = #(
    "request_id",
    json.int(keyboard_button_request_chat.request_id),
  )
  let chat_is_channel = #(
    "chat_is_channel",
    json.bool(keyboard_button_request_chat.chat_is_channel),
  )
  let chat_is_forum = #(
    "chat_is_forum",
    json.nullable(keyboard_button_request_chat.chat_is_forum, json.bool),
  )
  let chat_has_username = #(
    "chat_has_username",
    json.nullable(keyboard_button_request_chat.chat_has_username, json.bool),
  )
  let chat_is_created = #(
    "chat_is_created",
    json.nullable(keyboard_button_request_chat.chat_is_created, json.bool),
  )
  let user_administrator_rights = #(
    "user_administrator_rights",
    json.nullable(
      keyboard_button_request_chat.user_administrator_rights,
      encode_chat_administrator_rights,
    ),
  )
  let bot_administrator_rights = #(
    "bot_administrator_rights",
    json.nullable(
      keyboard_button_request_chat.bot_administrator_rights,
      encode_chat_administrator_rights,
    ),
  )
  let bot_is_member = #(
    "bot_is_member",
    json.nullable(keyboard_button_request_chat.bot_is_member, json.bool),
  )
  let request_title = #(
    "request_title",
    json.nullable(keyboard_button_request_chat.request_title, json.bool),
  )
  let request_username = #(
    "request_username",
    json.nullable(keyboard_button_request_chat.request_username, json.bool),
  )
  let request_photo = #(
    "request_photo",
    json.nullable(keyboard_button_request_chat.request_photo, json.bool),
  )

  json_object_filter_nulls([
    request_id,
    chat_is_channel,
    chat_is_forum,
    chat_has_username,
    chat_is_created,
    user_administrator_rights,
    bot_administrator_rights,
    bot_is_member,
    request_title,
    request_username,
    request_photo,
  ])
}

pub type KeyboardButtonPollType {
  /// This object represents type of a poll, which is allowed to be created and sent when the corresponding button is pressed.
  ///
  /// **Official reference:** https://core.telegram.org/bots/api#keyboardbuttonpolltype
  KeyboardButtonPollType(
    /// If quiz is passed, the user will be allowed to create only polls in the quiz mode. If regular is passed, only regular polls will be allowed. Otherwise, the user will be allowed to create a poll of any type.
    ///
    /// **Official reference:** https://core.telegram.org/bots/api#polltype
    ///
    /// **Note**: This type is a wrapper around the official type. The official field name is `type`.
    poll_type: Option(String),
  )
}

pub fn encode_keyboard_button_poll_type(
  keyboard_button_poll_type: KeyboardButtonPollType,
) -> Json {
  json_object_filter_nulls([
    #("type", json.nullable(keyboard_button_poll_type.poll_type, json.string)),
  ])
}

// ReplyParameters ---------------------------------------------------------------------

pub type ReplyParameters {
  /// Describes reply parameters for the message that is being sent.
  ///
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

pub fn encode_reply_parameters(reply_parameters: ReplyParameters) -> Json {
  let message_id = #("message_id", json.int(reply_parameters.message_id))
  let chat_id = #(
    "chat_id",
    json.nullable(reply_parameters.chat_id, encode_int_or_string),
  )
  let allow_sending_without_reply = #(
    "allow_sending_without_reply",
    json.nullable(reply_parameters.allow_sending_without_reply, json.bool),
  )
  let quote = #("quote", json.nullable(reply_parameters.quote, json.string))
  let quote_parse_mode = #(
    "quote_parse_mode",
    json.nullable(reply_parameters.quote_parse_mode, json.string),
  )
  let quote_entities = #(
    "quote_entities",
    json.nullable(reply_parameters.quote_entities, json.array(
      _,
      encode_message_entity,
    )),
  )
  let quote_position = #(
    "quote_position",
    json.nullable(reply_parameters.quote_position, json.int),
  )

  json_object_filter_nulls([
    message_id,
    chat_id,
    allow_sending_without_reply,
    quote,
    quote_parse_mode,
    quote_entities,
    quote_position,
  ])
}

// ReplyMarkup ---------------------------------------------------------------------
pub type ReplyMarkup {
  /// This object represents an inline keyboard that appears right next to the message it belongs to.
  ///
  /// **Official reference:** https://core.telegram.org/bots/api#inlinekeyboardmarkup
  ReplyInlineKeyboardMarkup(
    /// List of button rows, each represented by an List of [InlineKeyboardButton](https://core.telegram.org/bots/api#inlinekeyboardbutton) objects
    inline_keyboard: List(List(InlineKeyboardButton)),
  )
  /// This object represents a [custom keyboard](https://core.telegram.org/bots/features#keyboards) with reply options (see [Introduction to bots](https://core.telegram.org/bots/features#keyboards) for details and examples).
  ///
  /// **Official reference:** https://core.telegram.org/bots/api#replykeyboardmarkup
  ReplyKeyboardMarkup(
    /// Array of button rows, each represented by an Array of [KeyboardButton](https://core.telegram.org/bots/api#keyboardbutton) objects
    keyboard: List(List(KeyboardButton)),
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
  ///
  /// **Official reference:** https://core.telegram.org/bots/api#replykeyboardremove
  ReplyKeyboardRemove(
    /// Requests clients to remove the custom keyboard (user will not be able to summon this keyboard; if you want to hide the keyboard from sight but keep it accessible, use _one_time_keyboard_ in [ReplyKeyboardMarkup](https://core.telegram.org/bots/api#replykeyboardmarkup))
    remove_keyboard: Bool,
    /// Use this parameter if you want to show the keyboard to specific users only. Targets: 1) users that are @mentioned in the text of the [Message](https://core.telegram.org/bots/api#message) object; 2) if the bot's message is a reply to a message in the same chat and forum topic, sender of the original message.
    ///
    /// _Example_: A user requests to change the bot's language, bot replies to the request with a keyboard to select the new language. Other users in the group don't see the keyboard.
    selective: Option(Bool),
  )
  /// Upon receiving a message with this object, Telegram clients will display a reply interface to the user (act as if the user has selected the bot's message and tapped 'Reply'). This can be extremely useful if you want to create user-friendly step-by-step interfaces without having to sacrifice [privacy mode](https://core.telegram.org/bots/features#privacy-mode).
  ///
  /// **Official reference:** https://core.telegram.org/bots/api#forcereply
  ForceReply(
    /// Shows reply interface to the user, as if they manually selected the bot's message and tapped 'Reply'
    force_reply: Bool,
    /// The placeholder to be shown in the input field when the reply is active; 1-64 characters
    input_field_placeholder: String,
    /// Use this parameter if you want to force reply from specific users only. Targets: 1) users that are @mentioned in the text of the [Message](https://core.telegram.org/bots/api#message) object; 2) if the bot's message is a reply to a message in the same chat and forum topic, sender of the original message.
    selective: Bool,
  )
}

pub fn encode_reply_markup(reply_markup: ReplyMarkup) -> Json {
  case reply_markup {
    ReplyInlineKeyboardMarkup(inline_keyboard) ->
      json_object_filter_nulls([
        #(
          "inline_keyboard",
          json.array(inline_keyboard, json.array(
            _,
            encode_inline_keyboard_button,
          )),
        ),
      ])
    ReplyKeyboardMarkup(
      keyboard,
      is_persistent,
      resize_keyboard,
      one_time_keyboard,
      input_field_placeholder,
      selective,
    ) ->
      json_object_filter_nulls([
        #(
          "keyboard",
          json.array(keyboard, json.array(_, encode_keyboard_button)),
        ),
        #("is_persistent", json.nullable(is_persistent, json.bool)),
        #("resize_keyboard", json.nullable(resize_keyboard, json.bool)),
        #("one_time_keyboard", json.nullable(one_time_keyboard, json.bool)),
        #(
          "input_field_placeholder",
          json.nullable(input_field_placeholder, json.string),
        ),
        #("selective", json.nullable(selective, json.bool)),
      ])
    ReplyKeyboardRemove(remove_keyboard, selective) ->
      json_object_filter_nulls([
        #("remove_keyboard", json.bool(remove_keyboard)),
        #("selective", json.nullable(selective, json.bool)),
      ])
    ForceReply(force_reply, input_field_placeholder, selective) ->
      json_object_filter_nulls([
        #("force_reply", json.bool(force_reply)),
        #("input_field_placeholder", json.string(input_field_placeholder)),
        #("selective", json.bool(selective)),
      ])
  }
}

// SendDice ------------------------------------------------------------------------------------------------------------

pub type SendDiceParameters {
  SendDiceParameters(
    chat_id: IntOrString,
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

pub fn new_send_dice_parameters(
  chat_id chat_id: IntOrString,
) -> SendDiceParameters {
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
  let chat_id = #("chat_id", encode_int_or_string(params.chat_id))
  let message_thread_id = #(
    "message_thread_id",
    json.nullable(params.message_thread_id, json.int),
  )
  let emoji = #("emoji", json.nullable(params.emoji, json.string))
  let disable_notification = #(
    "disable_notification",
    json.nullable(params.disable_notification, json.bool),
  )
  let protect_content = #(
    "protect_content",
    json.nullable(params.protect_content, json.bool),
  )
  let reply_parameters = #(
    "reply_parameters",
    json.nullable(params.reply_parameters, encode_reply_parameters),
  )

  json_object_filter_nulls([
    chat_id,
    message_thread_id,
    emoji,
    disable_notification,
    protect_content,
    reply_parameters,
  ])
}

// WebhookInfo --------------------------------------------------------------------------------------------------------

pub type WebhookInfo {
  /// Describes the current status of a webhook.
  ///
  /// **Official reference:** [WebhookInfo](https://core.telegram.org/bots/api#webhookinfo)
  WebhookInfo(
    /// Webhook URL, may be empty if webhook is not set up
    url: String,
    /// _True_, if a custom certificate was provided for webhook certificate checks
    has_custom_certificate: Bool,
    /// Number of updates awaiting delivery
    pending_update_count: Int,
    /// Currently used webhook IP address
    ip_address: Option(String),
    /// Unix time for the most recent error that happened when trying to deliver an update via webhook
    last_error_date: Option(Int),
    /// Error message in human-readable format for the most recent error that happened when trying to deliver an update via webhook
    last_error_message: Option(String),
    /// Maximum allowed payload size for incoming update
    last_synchronization_error_date: Option(Int),
    /// Maximum allowed number of simultaneous HTTPS connections to the webhook for update delivery
    max_connections: Option(Int),
    /// A list of update types the bot is subscribed to. Defaults to all update types
    allowed_updates: Option(List(String)),
  )
}

pub fn decode_webhook_info(
  json: Dynamic,
) -> Result(WebhookInfo, dynamic.DecodeErrors) {
  json
  |> dynamic.decode9(
    WebhookInfo,
    dynamic.field("url", dynamic.string),
    dynamic.field("has_custom_certificate", dynamic.bool),
    dynamic.field("pending_update_count", dynamic.int),
    dynamic.optional_field("ip_address", dynamic.string),
    dynamic.optional_field("last_error_date", dynamic.int),
    dynamic.optional_field("last_error_message", dynamic.string),
    dynamic.optional_field("last_synchronization_error_date", dynamic.int),
    dynamic.optional_field("max_connections", dynamic.int),
    dynamic.optional_field("allowed_updates", dynamic.list(dynamic.string)),
  )
}

// WebAppInfo --------------------------------------------------------------------------------------------------------

pub type WebAppInfo {
  /// Describes a [Web App](https://core.telegram.org/bots/webapps).
  ///
  /// **Official reference:** [WebAppInfo](https://core.telegram.org/bots/api#webappinfo)
  WebAppInfo(
    /// An HTTPS URL of a Web App to be opened with additional data as specified in [Initializing Web Apps](https://core.telegram.org/bots/webapps#initializing-mini-apps)
    url: String,
  )
}

pub fn encode_web_app_info(info: WebAppInfo) -> Json {
  json_object_filter_nulls([#("url", json.string(info.url))])
}

pub fn decode_web_app_info(
  json: Dynamic,
) -> Result(WebAppInfo, dynamic.DecodeErrors) {
  json
  |> dynamic.decode1(WebAppInfo, dynamic.field("url", dynamic.string))
}

// WebAppData --------------------------------------------------------------------------------------------------------

pub type WebAppData {
  /// Describes data sent from a [Web App](https://core.telegram.org/bots/webapps) to the bot.
  WebAppData(
    /// The data. Be aware that a bad client can send arbitrary data in this field.
    data: String,
    /// Text of the _web_app_ keyboard button from which the Web App was opened. Be aware that a bad client can send arbitrary data in this field.
    button_text: String,
  )
}

pub fn decode_web_app_data(
  json: Dynamic,
) -> Result(WebAppData, dynamic.DecodeErrors) {
  json
  |> dynamic.decode2(
    WebAppData,
    dynamic.field("data", dynamic.string),
    dynamic.field("button_text", dynamic.string),
  )
}

// LoginUrl ----------------------------------------------------------------------------------------------------------

pub type LoginUrl {
  /// This object represents a parameter of the inline keyboard button used to automatically authorize a user. Serves as a great replacement for the [Telegram Login Widget](https://core.telegram.org/widgets/login) when the user is coming from Telegram. All the user needs to do is tap/click a button and confirm that they want to log in.
  LoginUrl(
    /// An HTTPS URL to be opened with user authorization data added to the query string when the button is pressed. If the user refuses to provide authorization data, the original URL without information about the user will be opened. The data added is the same as described in [Receiving authorization data](https://core.telegram.org/widgets/login#receiving-authorization-data).
    ///
    /// NOTE: You must always check the hash of the received data to verify the authentication and the integrity of the data as described in [Checking authorization](https://core.telegram.org/widgets/login#checking-authorization).
    url: String,
    /// New text of the button in forwarded messages.
    forward_text: Option(String),
    /// Username of a bot, which will be used for user authorization. [See Setting up a bot](https://core.telegram.org/widgets/login#setting-up-a-bot) for more details. If not specified, the current bot's username will be assumed. The url's domain must be the same as the domain linked with the bot. See [Linking your domain to the bot](https://core.telegram.org/widgets/login#linking-your-domain-to-the-bot) for more details.
    bot_username: Option(String),
    /// Pass _True_ to request the permission for your bot to send messages to the user.
    request_write_access: Option(Bool),
  )
}

pub fn encode_login_url(login_url: LoginUrl) -> Json {
  let url = #("url", json.string(login_url.url))
  let forward_text = #(
    "forward_text",
    json.nullable(login_url.forward_text, json.string),
  )
  let bot_username = #(
    "bot_username",
    json.nullable(login_url.bot_username, json.string),
  )
  let request_write_access = #(
    "request_write_access",
    json.nullable(login_url.request_write_access, json.bool),
  )

  json_object_filter_nulls([
    url,
    forward_text,
    bot_username,
    request_write_access,
  ])
}

pub fn decode_login_url(json: Dynamic) -> Result(LoginUrl, dynamic.DecodeErrors) {
  json
  |> dynamic.decode4(
    LoginUrl,
    dynamic.field("url", dynamic.string),
    dynamic.optional_field("forward_text", dynamic.string),
    dynamic.optional_field("bot_username", dynamic.string),
    dynamic.optional_field("request_write_access", dynamic.bool),
  )
}

// SwitchInlineQueryChosenChat ---------------------------------------------------------------------------------------

pub type SwitchInlineQueryChosenChat {
  /// This object represents an inline button that switches the current user to inline mode in a chosen chat, with an optional default inline query.
  SwitchInlineQueryChosenChat(
    /// The default inline query to be inserted in the input field. If left empty, only the bot's username will be inserted
    query: Option(String),
    /// True, if private chats with users can be chosen
    allow_user_chats: Option(Bool),
    /// True, if private chats with bots can be chosen
    allow_bot_chats: Option(Bool),
    /// True, if group and supergroup chats can be chosen
    allow_group_chats: Option(Bool),
    /// True, if channel chats can be chosen
    allow_channel_chats: Option(Bool),
  )
}

pub fn encode_switch_inline_query_chosen_chat(
  switch_inline_query_chosen_chat: SwitchInlineQueryChosenChat,
) -> Json {
  let query = #(
    "query",
    json.nullable(switch_inline_query_chosen_chat.query, json.string),
  )
  let allow_user_chats = #(
    "allow_user_chats",
    json.nullable(switch_inline_query_chosen_chat.allow_user_chats, json.bool),
  )
  let allow_bot_chats = #(
    "allow_bot_chats",
    json.nullable(switch_inline_query_chosen_chat.allow_bot_chats, json.bool),
  )
  let allow_group_chats = #(
    "allow_group_chats",
    json.nullable(switch_inline_query_chosen_chat.allow_group_chats, json.bool),
  )
  let allow_channel_chats = #(
    "allow_channel_chats",
    json.nullable(
      switch_inline_query_chosen_chat.allow_channel_chats,
      json.bool,
    ),
  )

  json_object_filter_nulls([
    query,
    allow_user_chats,
    allow_bot_chats,
    allow_group_chats,
    allow_channel_chats,
  ])
}

pub fn decode_switch_inline_query_chosen_chat(
  json: Dynamic,
) -> Result(SwitchInlineQueryChosenChat, dynamic.DecodeErrors) {
  json
  |> dynamic.decode5(
    SwitchInlineQueryChosenChat,
    dynamic.optional_field("query", dynamic.string),
    dynamic.optional_field("allow_user_chats", dynamic.bool),
    dynamic.optional_field("allow_bot_chats", dynamic.bool),
    dynamic.optional_field("allow_group_chats", dynamic.bool),
    dynamic.optional_field("allow_channel_chats", dynamic.bool),
  )
}

// ChatAdministratorRights -------------------------------------------------------------------------------------------

pub type ChatAdministratorRights {
  /// Represents the rights of an administrator in a chat.
  ///
  /// **Official reference:** [ChatAdministratorRights](https://core.telegram.org/bots/api#chatadministratorrights)
  ChatAdministratorRights(
    /// _True_, if the user's presence in the chat is hidden
    is_anonymous: Bool,
    /// _True_, if the administrator can access the chat event log, get boost list, see hidden supergroup and channel members, report spam messages and ignore slow mode. Implied by any other administrator privilege.
    can_manage_chat: Bool,
    /// _True_, if the administrator can delete messages of other users
    can_delete_messages: Bool,
    /// _True_, if the administrator can manage video chats
    can_manage_voice_chats: Bool,
    /// _True_, if the administrator can restrict, ban or unban chat members, or access supergroup statistics
    can_restrict_members: Bool,
    /// _True_, if the administrator can add new administrators with a subset of their own privileges or demote administrators that they have promoted, directly or indirectly (promoted by administrators that were appointed by the user)
    can_promote_members: Bool,
    /// _True_, if the user is allowed to change the chat title, photo and other settings
    can_change_info: Bool,
    /// _True_, if the user is allowed to invite new users to the chat
    can_invite_users: Bool,
    /// _True_, if the administrator can post stories to the chat
    can_post_stories: Bool,
    /// _True_, if the administrator can edit stories posted by other users
    can_edit_stories: Bool,
    /// _True_, if the administrator can delete stories posted by other users
    can_delete_stories: Bool,
    /// _True_, if the administrator can post messages in the channel, or access channel statistics; for channels only
    can_post_messages: Option(Bool),
    /// _True_, if the administrator can edit messages of other users and can pin messages; for channels only
    can_edit_messages: Option(Bool),
    /// _True_, if the user is allowed to pin messages; for groups and supergroups only
    can_pin_messages: Option(Bool),
    /// _True_, if the user is allowed to create, rename, close, and reopen forum topics; for supergroups only
    can_manage_topics: Option(Bool),
  )
}

pub fn encode_chat_administrator_rights(
  chat_administrator_rights: ChatAdministratorRights,
) -> Json {
  let is_anonymous = #(
    "is_anonymous",
    json.bool(chat_administrator_rights.is_anonymous),
  )

  let can_manage_chat = #(
    "can_manage_chat",
    json.bool(chat_administrator_rights.can_manage_chat),
  )
  let can_delete_messages = #(
    "can_delete_messages",
    json.bool(chat_administrator_rights.can_delete_messages),
  )
  let can_manage_voice_chats = #(
    "can_manage_voice_chats",
    json.bool(chat_administrator_rights.can_manage_voice_chats),
  )
  let can_restrict_members = #(
    "can_restrict_members",
    json.bool(chat_administrator_rights.can_restrict_members),
  )
  let can_promote_members = #(
    "can_promote_members",
    json.bool(chat_administrator_rights.can_promote_members),
  )
  let can_change_info = #(
    "can_change_info",
    json.bool(chat_administrator_rights.can_change_info),
  )
  let can_invite_users = #(
    "can_invite_users",
    json.bool(chat_administrator_rights.can_invite_users),
  )
  let can_post_stories = #(
    "can_post_stories",
    json.bool(chat_administrator_rights.can_post_stories),
  )
  let can_edit_stories = #(
    "can_edit_stories",
    json.bool(chat_administrator_rights.can_edit_stories),
  )
  let can_delete_stories = #(
    "can_delete_stories",
    json.bool(chat_administrator_rights.can_delete_stories),
  )
  let can_post_messages = #(
    "can_post_messages",
    json.nullable(chat_administrator_rights.can_post_messages, json.bool),
  )
  let can_edit_messages = #(
    "can_edit_messages",
    json.nullable(chat_administrator_rights.can_edit_messages, json.bool),
  )
  let can_pin_messages = #(
    "can_pin_messages",
    json.nullable(chat_administrator_rights.can_pin_messages, json.bool),
  )
  let can_manage_topics = #(
    "can_manage_topics",
    json.nullable(chat_administrator_rights.can_manage_topics, json.bool),
  )

  json_object_filter_nulls([
    is_anonymous,
    can_manage_chat,
    can_delete_messages,
    can_manage_voice_chats,
    can_restrict_members,
    can_promote_members,
    can_change_info,
    can_invite_users,
    can_post_stories,
    can_edit_stories,
    can_delete_stories,
    can_post_messages,
    can_edit_messages,
    can_pin_messages,
    can_manage_topics,
  ])
}

// LinkPreviewOptions ------------------------------------------------------------------------------------------------

pub type LinkPreviewOptions {
  /// Describes the options used for link preview generation.
  ///
  /// **Official reference:** [LinkPreviewOptions](https://core.telegram.org/bots/api#linkpreviewoptions)
  LinkPreviewOptions(
    /// _True_, if the link preview is disabled
    is_disabled: Option(Bool),
    /// URL to use for the link preview. If empty, then the first URL found in the message text will be used
    url: Option(String),
    /// _True_, if the media in the link preview is supposed to be shrunk; ignored if the URL isn't explicitly specified or media size change isn't supported for the preview
    prefer_small_media: Option(Bool),
    /// _True_, if the media in the link preview is supposed to be enlarged; ignored if the URL isn't explicitly specified or media size change isn't supported for the preview
    prefer_large_media: Option(Bool),
    /// _True_, if the link preview must be shown above the message text; otherwise, the link preview will be shown below the message text
    show_above_text: Option(Bool),
  )
}

pub fn encode_link_preview_options(
  link_preview_options: LinkPreviewOptions,
) -> Json {
  json_object_filter_nulls([
    #("is_disabled", json.nullable(link_preview_options.is_disabled, json.bool)),
    #("url", json.nullable(link_preview_options.url, json.string)),
    #(
      "prefer_small_media",
      json.nullable(link_preview_options.prefer_small_media, json.bool),
    ),
    #(
      "prefer_large_media",
      json.nullable(link_preview_options.prefer_large_media, json.bool),
    ),
    #(
      "show_above_text",
      json.nullable(link_preview_options.show_above_text, json.bool),
    ),
  ])
}

// CallbackQuery -----------------------------------------------------------------------------------------------------

pub type CallbackQuery {
  /// This object represents an incoming callback query from a callback button in an [inline keyboard](https://core.telegram.org/bots/features#inline-keyboards).
  /// If the button that originated the query was attached to a message sent by the bot, the field message will be present.
  /// If the button was attached to a message sent via the bot (in [inline mode](https://core.telegram.org/bots/api#inline-mode)), the field _inline_message_id_ will be present.
  /// Exactly one of the fields data or _game_short_name_ will be present.
  ///
  /// > **NOTE:** After the user presses a callback button, Telegram clients will display a progress bar until you call [answerCallbackQuery](https://core.telegram.org/bots/api#answercallbackquery).
  /// > It is, therefore, necessary to react by calling [answerCallbackQuery](https://core.telegram.org/bots/api#answercallbackquery) even if no notification to the user is needed (e.g., without specifying any of the optional parameters).
  ///
  /// **Official reference:** [CallbackQuery](https://core.telegram.org/bots/api#callbackquery)
  CallbackQuery(
    /// Unique identifier for this query
    id: String,
    /// Sender
    from: User,
    /// Message sent by the bot with the callback button that originated the query
    message: Option(MaybeInaccessibleMessage),
    /// Identifier of the message sent via the bot in inline mode, that originated the query.
    inline_message_id: Option(String),
    /// Global identifier, uniquely corresponding to the chat to which the message with the callback button was sent. Useful for high scores in [games](https://core.telegram.org/bots/api#games).
    chat_instance: Option(String),
    /// Data associated with the callback button. Be aware that the message originated the query can contain no callback buttons with this data.
    data: Option(String),
    /// Short name of a [Game](https://core.telegram.org/bots/api#games) to be returned, serves as the unique identifier for the game
    game_short_name: Option(String),
  )
}

pub fn decode_callback_query(
  json: Dynamic,
) -> Result(CallbackQuery, dynamic.DecodeErrors) {
  json
  |> dynamic.decode7(
    CallbackQuery,
    dynamic.field("id", dynamic.string),
    dynamic.field("from", decode_user),
    dynamic.optional_field("message", decode_maybe_inaccessible_message),
    dynamic.optional_field("inline_message_id", dynamic.string),
    dynamic.optional_field("chat_instance", dynamic.string),
    dynamic.optional_field("data", dynamic.string),
    dynamic.optional_field("game_short_name", dynamic.string),
  )
}

// InaccessibleMessage -----------------------------------------------------------------------------------------------

pub type InaccessibleMessage {
  /// This object describes a message that was deleted or is otherwise inaccessible to the bot.
  ///
  /// **Official reference:** [InaccessibleMessage](https://core.telegram.org/bots/api#inaccessiblemessage)
  InaccessibleMessage(
    /// Chat the message belonged to
    chat: Chat,
    /// Unique message identifier inside the chat
    message_id: Int,
    /// Always 0. The field can be used to differentiate regular and inaccessible messages.
    date: Int,
  )
}

pub fn decode_inaccessible_message(
  json: Dynamic,
) -> Result(InaccessibleMessage, dynamic.DecodeErrors) {
  json
  |> dynamic.decode3(
    InaccessibleMessage,
    dynamic.field("chat", decode_chat),
    dynamic.field("message_id", dynamic.int),
    dynamic.field("date", dynamic.int),
  )
}

// MaybeInaccessibleMessage ------------------------------------------------------------------------------------------

/// This object describes a message that can be inaccessible to the bot.
///
/// **Official reference:** [MaybeInaccessibleMessage](https://core.telegram.org/bots/api#maybeinaccessiblemessage)
pub type MaybeInaccessibleMessage {
  MaybeInaccessibleMessageMessage(Message)
  MaybeInaccessibleMessageInaccessible(InaccessibleMessage)
}

pub fn decode_maybe_inaccessible_message(
  json: Dynamic,
) -> Result(MaybeInaccessibleMessage, dynamic.DecodeErrors) {
  case
    json
    |> dynamic.field("date", dynamic.int)
  {
    Ok(date) ->
      case date == 0 {
        True ->
          case decode_inaccessible_message(json) {
            Ok(inaccessible_message) ->
              Ok(MaybeInaccessibleMessageInaccessible(inaccessible_message))
            Error(errors) -> Error(errors)
          }
        False ->
          case decode_message(json) {
            Ok(message) -> Ok(MaybeInaccessibleMessageMessage(message))
            Error(errors) -> Error(errors)
          }
      }
    Error(errors) -> Error(errors)
  }
}

// EditMessageTextParameters ------------------------------------------------------------------------------------------

pub type EditMessageTextParameters {
  EditMessageTextParameters(
    /// Required if _inline_message_id_ is not specified.
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: Option(IntOrString),
    /// Required if inline_message_id is not specified. Identifier of the message to edit
    message_id: Option(Int),
    /// Required if _chat_id_ and _message_id_ are not specified. Identifier of the inline message
    inline_message_id: Option(String),
    /// New text of the message, 1-4096 characters after entities parsing
    text: String,
    /// Mode for parsing entities in the message text. See [formatting options](https://core.telegram.org/bots/api#formatting-options) for more details.
    parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in message text, which can be specified instead of _parse_mode_
    entities: Option(List(MessageEntity)),
    /// Link preview generation options for the message
    link_preview_options: Option(LinkPreviewOptions),
    /// A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots/features#inline-keyboards).
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

pub fn default_edit_message_text_parameters() -> EditMessageTextParameters {
  EditMessageTextParameters(
    chat_id: None,
    message_id: None,
    inline_message_id: None,
    text: "",
    parse_mode: None,
    entities: None,
    link_preview_options: None,
    reply_markup: None,
  )
}

pub fn encode_edit_message_text_parameters(
  params: EditMessageTextParameters,
) -> Json {
  let chat_id = #(
    "chat_id",
    json.nullable(params.chat_id, encode_int_or_string),
  )
  let message_id = #("message_id", json.nullable(params.message_id, json.int))
  let inline_message_id = #(
    "inline_message_id",
    json.nullable(params.inline_message_id, json.string),
  )
  let text = #("text", json.string(params.text))
  let parse_mode = #(
    "parse_mode",
    json.nullable(params.parse_mode, json.string),
  )
  let entities = #(
    "entities",
    json.nullable(params.entities, json.array(_, encode_message_entity)),
  )
  let link_preview_options = #(
    "link_preview_options",
    json.nullable(params.link_preview_options, encode_link_preview_options),
  )
  let reply_markup = #(
    "reply_markup",
    json.nullable(params.reply_markup, encode_inline_keyboard_markup),
  )

  json_object_filter_nulls([
    chat_id,
    message_id,
    inline_message_id,
    text,
    parse_mode,
    entities,
    link_preview_options,
    reply_markup,
  ])
}

pub type EditMessageTextResult {
  EditMessageTextMessage(Message)
  EditMessageTextBool(Bool)
}

pub fn decode_edit_message_text_result(
  json: Dynamic,
) -> Result(EditMessageTextResult, dynamic.DecodeErrors) {
  case dynamic.bool(json) {
    Ok(bool) -> Ok(EditMessageTextBool(bool))
    Error(_) ->
      decode_message(json)
      |> result.map(EditMessageTextMessage)
  }
}

// AnswerCallbackQueryParameters --------------------------------------------------------------------------------------
// https://core.telegram.org/bots/api#answercallbackquery
pub type AnswerCallbackQueryParameters {
  AnswerCallbackQueryParameters(
    /// Unique identifier for the query to be answered
    callback_query_id: String,
    /// Text of the notification. If not specified, nothing will be shown to the user
    text: Option(String),
    /// If true, an alert will be shown by the client instead of a notification at the top of the chat screen. Defaults to false.
    show_alert: Option(Bool),
    /// URL that will be opened by the user's client. If you have created a [Game](https://core.telegram.org/bots/api#games), you can use this
    /// field to redirect the player to your game
    url: Option(String),
    /// The maximum amount of time in seconds that the result of the callback query may be cached client-side. Telegram apps will support
    /// caching starting in version 3.14. Defaults to 0.
    cache_time: Option(Int),
  )
}

pub fn new_answer_callback_query_parameters(
  callback_query_id: String,
) -> AnswerCallbackQueryParameters {
  AnswerCallbackQueryParameters(
    callback_query_id: callback_query_id,
    text: None,
    show_alert: None,
    url: None,
    cache_time: None,
  )
}

pub fn encode_answer_callback_query_parameters(
  params: AnswerCallbackQueryParameters,
) -> Json {
  let callback_query_id = #(
    "callback_query_id",
    json.string(params.callback_query_id),
  )
  let text = #("text", json.nullable(params.text, json.string))
  let show_alert = #("show_alert", json.nullable(params.show_alert, json.bool))
  let url = #("url", json.nullable(params.url, json.string))
  let cache_time = #("cache_time", json.nullable(params.cache_time, json.int))

  json_object_filter_nulls([
    callback_query_id,
    text,
    show_alert,
    url,
    cache_time,
  ])
}

// Common ------------------------------------------------------------------------------------------------------------

pub type IntOrString {
  Inted(Int)
  Stringed(String)
}

fn encode_int_or_string(value: IntOrString) -> Json {
  case value {
    Inted(value) -> json.int(value)
    Stringed(value) -> json.string(value)
  }
}

fn all_errors(
  result: Result(a, List(dynamic.DecodeError)),
) -> List(dynamic.DecodeError) {
  case result {
    Ok(_) -> []
    Error(errors) -> errors
  }
}

fn json_object_filter_nulls(entries: List(#(String, Json))) -> Json {
  let null = json.null()

  entries
  |> list.filter(fn(entry) {
    let #(_, value) = entry
    case value == null {
      True -> False
      False -> True
    }
  })
  |> json.object
}
