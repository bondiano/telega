import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import gleam/list
import telega/models/message_entity.{type MessageEntity}
import telega/models/user.{type User}
import telega/models/keyboard.{type InlineKeyboardMarkup}

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

fn chat_decoder() {
  dynamic.decode5(
    Chat,
    dynamic.field("id", dynamic.int),
    dynamic.optional_field("username", dynamic.string),
    dynamic.optional_field("first_name", dynamic.string),
    dynamic.optional_field("last_name", dynamic.string),
    dynamic.optional_field("is_forum", dynamic.bool),
  )
}

pub fn decode(json: Dynamic) -> Result(Message, dynamic.DecodeErrors) {
  let decode_chat = chat_decoder()
  let decode_message_id = dynamic.field("message_id", dynamic.int)
  let decode_message_thread_id =
    dynamic.optional_field("message_thread_id", dynamic.int)
  let decode_from = dynamic.optional_field("from", user.decode)
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
    dynamic.optional_field("reply_to_message", decode)
  let decode_via_bot = dynamic.optional_field("via_bot", user.decode)
  let decode_edit_date = dynamic.optional_field("edit_date", dynamic.int)
  let decode_has_protected_content =
    dynamic.optional_field("has_protected_content", dynamic.bool)
  let decode_media_group_id =
    dynamic.optional_field("media_group_id", dynamic.string)
  let decode_author_signature =
    dynamic.optional_field("author_signature", dynamic.string)
  let decode_text = dynamic.optional_field("text", dynamic.string)
  let decode_entities =
    dynamic.optional_field("entities", dynamic.list(message_entity.decode))
  let decode_caption = dynamic.optional_field("caption", dynamic.string)
  let decode_caption_entities =
    dynamic.optional_field(
      "caption_entities",
      dynamic.list(message_entity.decode),
    )
  let decode_has_media_spoiler =
    dynamic.optional_field("has_media_spoiler", dynamic.bool)
  let decode_new_chat_members =
    dynamic.optional_field("new_chat_members", dynamic.list(user.decode))
  let decode_left_chat_member =
    dynamic.optional_field("left_chat_member", user.decode)
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
    dynamic.optional_field("reply_markup", keyboard.decode_inline_markup)

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
