import gleam/option.{type Option}
import telega/api
import telega/bot.{type Context}
import telega/model.{
  type AnswerCallbackQueryParameters, type EditMessageTextParameters,
  type EditMessageTextResult, type ForwardMessageParameters,
  type Message as ModelMessage, type ReplyMarkup, type SendDiceParameters,
}

/// Use this method to send text messages.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_text(
  ctx ctx: Context(session),
  text text: String,
) -> Result(ModelMessage, String) {
  api.send_message(
    ctx.config.api,
    parameters: model.new_send_message_parameters(
      text: text,
      chat_id: model.Stringed(ctx.key),
    ),
  )
}

/// Use this method to send text messages with keyboard markup.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_markup(
  ctx ctx: Context(session),
  text text: String,
  markup reply_markup: ReplyMarkup,
) {
  api.send_message(
    ctx.config.api,
    parameters: model.new_send_message_parameters(
      text: text,
      chat_id: model.Stringed(ctx.key),
    )
      |> model.set_send_message_parameters_reply_markup(reply_markup),
  )
}

/// Use this method to send an animated emoji that will display a random value.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddice
pub fn with_dice(
  ctx ctx: Context(session),
  parameters parameters: Option(SendDiceParameters),
) -> Result(ModelMessage, String) {
  let parameters =
    parameters
    |> option.lazy_unwrap(fn() {
      model.new_send_dice_parameters(model.Stringed(ctx.key))
    })

  api.send_dice(ctx.config.api, parameters)
}

/// Use this method to edit text and game messages.
/// On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagetext
pub fn edit_text(
  ctx ctx: Context(session),
  parameters parameters: EditMessageTextParameters,
) -> Result(EditMessageTextResult, String) {
  api.edit_message_text(ctx.config.api, parameters)
}

/// Use this method to forward messages of any kind. Service messages and messages with protected content can't be forwarded.
/// On success, the sent Message is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#forwardmessage
pub fn forward(
  ctx ctx: Context(session),
  parameters parameters: ForwardMessageParameters,
) -> Result(ModelMessage, String) {
  api.forward_message(ctx.config.api, parameters)
}

/// Use this method to send answers to callback queries sent from inline keyboards.
/// The answer will be displayed to the user as a notification at the top of the chat screen or as an alert.
/// On success, _True_ is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#answercallbackquery
pub fn answer_callback_query(
  ctx ctx: Context(session),
  parameters parameters: AnswerCallbackQueryParameters,
) -> Result(Bool, String) {
  api.answer_callback_query(ctx.config.api, parameters)
}
