import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/http.{Get, Post}
import gleam/option.{type Option, None, Some}
import gleam/json
import gleam/httpc
import gleam/result
import gleam/dynamic

type TelegramApiRequest {
  TelegramApiPostRequest(
    url: String,
    body: String,
    query: Option(List(#(String, String))),
  )
  TelegramApiGetRequest(url: String, query: Option(List(#(String, String))))
}

pub type BotCommand {
  BotCommand(
    /// Text of the command; 1-32 characters. Can contain only lowercase English letters, digits and underscores.
    command: String,
    /// Description of the command; 1-256 characters.
    description: String,
  )
}

pub type BotCommands =
  List(BotCommand)

pub type IntOrString {
  Int(Int)
  String(String)
}

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

pub type BotCommandsOptions {
  BotCommandsOptions(
    /// An object, describing scope of users for which the commands are relevant. Defaults to `BotCommandScopeDefault`.
    scope: Option(BotCommandScope),
    /// A two-letter ISO 639-1 language code. If empty, commands will be applied to all users from the given scope, for whose language there are no dedicated commands
    language_code: Option(String),
  )
}

// TODO: Support all options
/// **Official reference:** https://core.telegram.org/bots/api#setwebhook
pub fn set_webhook(
  token token: String,
  telegram_url telegram_url: String,
  webhook_url webhook_url: String,
  secret_token secret_token: Option(String),
) -> Result(Response(String), String) {
  let query = [#("url", webhook_url)]
  let query = case secret_token {
    None -> query
    Some(secret_token) -> [#("secret_token", secret_token), ..query]
  }

  new_get_request(
    token: token,
    telegram_url: telegram_url,
    path: "setWebhook",
    query: Some(query),
  )
  |> api_to_request
  |> fetch
}

// TODO: Support all options
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn send_message(
  token token: String,
  telegram_url telegram_url: String,
  chat_id chat_id: Int,
  text text: String,
) -> Result(Response(String), String) {
  new_post_request(
    token: token,
    telegram_url: telegram_url,
    path: "sendMessage",
    body: json.object([
        #("chat_id", json.int(chat_id)),
        #("text", json.string(text)),
      ])
      |> json.to_string,
    query: None,
  )
  |> api_to_request
  |> fetch
}

/// **Official reference:** https://core.telegram.org/bots/api#setmycommands
pub fn set_my_commands(
  token token: String,
  telegram_url telegram_url: String,
  commands commands: BotCommands,
  options options: Option(BotCommandsOptions),
) -> Result(Response(String), String) {
  let options = case options {
    None -> []
    Some(options) -> {
      let scope = case options.scope {
        None -> []
        Some(scope) -> [#("scope", bot_command_scope_to_json(scope))]
      }

      case options.language_code {
        None -> scope
        Some(language_code) -> [
          #("language_code", json.string(language_code)),
          ..scope
        ]
      }
    }
  }

  let body_json =
    json.object([
      #(
        "commands",
        json.array(commands, fn(command: BotCommand) {
          json.object([
            #("command", json.string(command.command)),
            #("description", json.string(command.description)),
            ..options
          ])
        }),
      ),
    ])

  new_post_request(
    token: token,
    telegram_url: telegram_url,
    path: "setMyCommands",
    body: json.to_string(body_json),
    query: None,
  )
  |> api_to_request
  |> fetch
}

fn new_post_request(
  token token: String,
  telegram_url telegram_url: String,
  path path: String,
  body body: String,
  query query: Option(List(#(String, String))),
) {
  let url = telegram_url <> token <> "/" <> path

  TelegramApiPostRequest(url: url, body: body, query: query)
}

fn new_get_request(
  token token: String,
  telegram_url telegram_url: String,
  path path: String,
  query query: Option(List(#(String, String))),
) {
  let url = telegram_url <> token <> "/" <> path

  TelegramApiGetRequest(url: url, query: query)
}

fn set_query(
  api_request: Request(String),
  query: Option(List(#(String, String))),
) -> Request(String) {
  case query {
    None -> api_request
    Some(query) -> {
      request.set_query(api_request, query)
    }
  }
}

fn api_to_request(
  api_request: TelegramApiRequest,
) -> Result(Request(String), String) {
  case api_request {
    TelegramApiGetRequest(url: url, query: query) -> {
      request.to(url)
      |> result.map(request.set_method(_, Get))
      |> result.map(set_query(_, query))
      |> result.map(request.set_header(_, "Content-Type", "application/json"))
    }
    TelegramApiPostRequest(url: url, query: query, body: body) -> {
      request.to(url)
      |> result.map(request.set_body(_, body))
      |> result.map(request.set_method(_, Post))
      |> result.map(request.set_header(_, "Content-Type", "application/json"))
      |> result.map(set_query(_, query))
    }
  }
  |> result.map_error(fn(_) { "Failed to convert API request to HTTP request" })
}

fn fetch(api_request: Result(Request(String), String)) {
  use api_request <- result.try(api_request)

  httpc.send(api_request)
  |> result.map_error(fn(error) {
    dynamic.string(error)
    |> result.unwrap("Failed to send request")
  })
}

fn string_or_int_to_json(value: IntOrString) {
  case value {
    Int(value) -> json.int(value)
    String(value) -> json.string(value)
  }
}

fn bot_command_scope_to_json(scope: BotCommandScope) {
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
