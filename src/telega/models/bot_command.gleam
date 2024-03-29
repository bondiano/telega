import gleam/option.{type Option, None}
import gleam/json.{type Json}
import gleam/list
import gleam/dynamic.{type Dynamic}
import telega/models/common.{type IntOrString}

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

pub fn decode(json: Dynamic) -> Result(List(BotCommand), dynamic.DecodeErrors) {
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
    params.scope
    |> option.map(fn(scope) { [#("scope", scope_to_json(scope))] })
    |> option.unwrap([])

  let language_code =
    params.language_code
    |> option.map(fn(language_code) {
      [#("language_code", json.string(language_code))]
    })
    |> option.unwrap([])

  list.concat([scope, language_code])
}

pub fn scope_to_json(scope: BotCommandScope) {
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
        #("chat_id", common.string_or_int_to_json(chat_id)),
      ])
    BotCommandScopeChatAdministrators(chat_id: chat_id) ->
      json.object([
        #("type", json.string("chat_administrators")),
        #("chat_id", common.string_or_int_to_json(chat_id)),
      ])
    BotCommandScopeChatMember(chat_id: chat_id, user_id: user_id) ->
      json.object([
        #("type", json.string("chat_member")),
        #("chat_id", common.string_or_int_to_json(chat_id)),
        #("user_id", json.int(user_id)),
      ])
  }
}

pub fn from(commands: List(#(String, String))) -> List(BotCommand) {
  commands
  |> list.map(fn(command) {
    let #(command, description) = command
    BotCommand(command: command, description: description)
  })
}
