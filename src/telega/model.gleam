import gleam/list
import gleam/option.{type Option, None}
import gleam/json.{type Json}
import gleam/dynamic.{type Dynamic}

// Reply ------------------------------------------------------------------------

pub type Update {
  /// **Official reference:** https://core.telegram.org/bots/api#update
  Update(
    message: Message,
    /// The update's unique identifier.
    update_id: Int,
  )
}

/// Decode a message from the Telegram API.
pub fn decode_update(json: Dynamic) -> Result(Update, dynamic.DecodeErrors) {
  json
  |> dynamic.decode2(
    Update,
    dynamic.field("message", decode_message),
    dynamic.field("update_id", dynamic.int),
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
    // TODO: web_app_data
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
    decode_inline_keyboard_markup(json)
  {
    Ok(message_id), Ok(message_thread_id), Ok(from), Ok(sender_chat), Ok(
      sender_boost_count,
    ), Ok(date), Ok(chat), Ok(is_topic_message), Ok(is_automatic_forward), Ok(
      reply_to_message,
    ), Ok(via_bot), Ok(edit_date), Ok(has_protected_content), Ok(media_group_id), Ok(
      author_signature,
    ), Ok(text), Ok(entities), Ok(caption), Ok(caption_entities), Ok(
      has_media_spoiler,
    ), Ok(new_chat_members), Ok(left_chat_member), Ok(new_chat_title), Ok(
      delete_chat_photo,
    ), Ok(group_chat_created), Ok(supergroup_chat_created), Ok(
      channel_chat_created,
    ), Ok(migrate_to_chat_id), Ok(migrate_from_chat_id), Ok(connected_website), Ok(
      inline_keyboard_markup,
    ) ->
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
        reply_markup: inline_keyboard_markup,
      ))
    message_id, message_thread_id, from, sender_chat, sender_boost_count, date, chat, is_topic_message, is_automatic_forward, reply_to_message, via_bot, edit_date, has_protected_content, media_group_id, author_signature, text, entities, caption, caption_entities, has_media_spoiler, new_chat_members, left_chat_member, new_chat_title, delete_chat_photo, group_chat_created, supergroup_chat_created, channel_chat_created, migrate_to_chat_id, migrate_from_chat_id, connected_website, inline_keyboard_markup ->
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
        ]),
      )
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

pub type BotCommandParameters {
  BotCommandParameters(
    /// An object, describing scope of users for which the commands are relevant. Defaults to `BotCommandScopeDefault`.
    scope: Option(BotCommandScope),
    /// A two-letter ISO 639-1 language code. If empty, commands will be applied to all users from the given scope, for whose language there are no dedicated commands
    language_code: Option(String),
  )
}

pub fn new_botcommand_parameters() -> BotCommandParameters {
  BotCommandParameters(scope: None, language_code: None)
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

pub fn encode_botcommand_parameters(
  params: BotCommandParameters,
) -> List(#(String, Json)) {
  let scope =
    option_to_json_object_list(params.scope, "scope", bot_command_scope_to_json)

  let language_code =
    option_to_json_object_list(
      params.language_code,
      "language_code",
      json.string,
    )

  list.concat([scope, language_code])
}

pub fn bot_command_scope_to_json(scope: BotCommandScope) {
  case scope {
    BotCommandDefaultScope -> json.object([#("type", json.string("default"))])
    BotCommandAllPrivateChatsScope ->
      json.object([#("type", json.string("all_private_chats"))])
    BotCommandScopeAllGroupChats ->
      json.object([#("type", json.string("all_group_chats"))])
    BotCommandScopeAllChatAdministrators ->
      json.object([#("type", json.string("all_chat_administrators"))])
    BotCommandScopeChat(chat_id: chat_id) ->
      json.object([
        #("type", json.string("chat")),
        #("chat_id", json.int(chat_id)),
      ])
    BotCommandScopeChatString(chat_id: chat_id) ->
      json.object([
        #("type", json.string("chat")),
        #("chat_id", string_or_int_to_json(chat_id)),
      ])
    BotCommandScopeChatAdministrators(chat_id: chat_id) ->
      json.object([
        #("type", json.string("chat_administrators")),
        #("chat_id", string_or_int_to_json(chat_id)),
      ])
    BotCommandScopeChatMember(chat_id: chat_id, user_id: user_id) ->
      json.object([
        #("type", json.string("chat_member")),
        #("chat_id", string_or_int_to_json(chat_id)),
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
  let id = [#("id", json.int(user.id))]
  let is_bot = [#("is_bot", json.bool(user.is_bot))]
  let first_name = [#("first_name", json.string(user.first_name))]
  let last_name =
    option_to_json_object_list(user.last_name, "last_name", json.string)
  let username =
    option_to_json_object_list(user.username, "username", json.string)
  let language_code =
    option_to_json_object_list(user.language_code, "language_code", json.string)
  let is_premium =
    option_to_json_object_list(user.is_premium, "is_premium", json.bool)
  let added_to_attachment_menu =
    option_to_json_object_list(
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
  let entity_type = [#("entity_type", json.string(message_entity.entity_type))]
  let offset = [#("offset", json.int(message_entity.offset))]
  let length = [#("length", json.int(message_entity.length))]
  let url = option_to_json_object_list(message_entity.url, "url", json.string)
  let user =
    option_to_json_object_list(message_entity.user, "user", encode_user)
  let language =
    option_to_json_object_list(message_entity.language, "language", json.string)
  let custom_emoji_id =
    option_to_json_object_list(
      message_entity.custom_emoji_id,
      "custom_emoji_id",
      json.string,
    )

  [entity_type, offset, length, url, user, language, custom_emoji_id]
  |> list.concat
  |> json.object
}

// Keyboard ---------------------------------------------------------------------

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

// ReplyParameters ---------------------------------------------------------------------

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
  ReplyInlineKeyboardMarkup(
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
    option_to_json_object_list(
      reply_parameters.chat_id,
      "chat_id",
      string_or_int_to_json,
    )
  let allow_sending_without_reply =
    option_to_json_object_list(
      reply_parameters.allow_sending_without_reply,
      "allow_sending_without_reply",
      json.bool,
    )
  let quote =
    option_to_json_object_list(reply_parameters.quote, "quote", json.string)
  let quote_parse_mode =
    option_to_json_object_list(
      reply_parameters.quote_parse_mode,
      "quote_parse_mode",
      json.string,
    )
  let quote_entities =
    option_to_json_object_list(
      reply_parameters.quote_entities,
      "quote_entities",
      json.array(_, encode_message_entity),
    )
  let quote_position =
    option_to_json_object_list(
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

// SendDice ------------------------------------------------------------------------------------------------------------

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
    option_to_json_object_list(
      params.message_thread_id,
      "message_thread_id",
      json.int,
    )
  let emoji = option_to_json_object_list(params.emoji, "emoji", json.string)
  let disable_notification =
    option_to_json_object_list(
      params.disable_notification,
      "disable_notification",
      json.bool,
    )
  let protect_content =
    option_to_json_object_list(
      params.protect_content,
      "protect_content",
      json.bool,
    )
  let reply_parameters =
    option_to_json_object_list(
      params.reply_parameters,
      "reply_parameters",
      encode_reply_parameters,
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

// Common ------------------------------------------------------------------------------------------------------------

pub type IntOrString {
  Int(Int)
  String(String)
}

fn string_or_int_to_json(value: IntOrString) -> Json {
  case value {
    Int(value) -> json.int(value)
    String(value) -> json.string(value)
  }
}

fn option_to_json_object_list(
  value value: Option(a),
  field field: String,
  encoder encoder: fn(a) -> Json,
) -> List(#(String, Json)) {
  option.map(value, fn(v) { [#(field, encoder(v))] })
  |> option.unwrap([])
}
