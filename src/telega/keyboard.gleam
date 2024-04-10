//// This module contains the keyboard constructors and usefull utilities to work with keyboards

import gleam/string
import gleam/result
import gleam/option.{type Option, None, Some}
import telega/model.{
  type InlineKeyboardButton, type KeyboardButton, type ReplyMarkup,
  InlineKeyboardButton, KeyboardButton, ReplyInlineKeyboardMarkup,
  ReplyKeyboardMarkup,
}

// Keyboard -------------------------------------------------------------------------------------------

pub opaque type Keyboard {
  Keyboard(
    buttons: List(List(KeyboardButton)),
    is_persistent: Option(Bool),
    resize_keyboard: Option(Bool),
    one_time_keyboard: Option(Bool),
    input_field_placeholder: Option(String),
    selective: Option(Bool),
  )
}

pub fn new(buttons: List(List(KeyboardButton))) -> Keyboard {
  Keyboard(
    buttons: buttons,
    is_persistent: None,
    resize_keyboard: None,
    one_time_keyboard: None,
    input_field_placeholder: None,
    selective: None,
  )
}

pub fn build(keyboard: Keyboard) -> ReplyMarkup {
  ReplyKeyboardMarkup(
    keyboard: keyboard.buttons,
    resize_keyboard: keyboard.resize_keyboard,
    one_time_keyboard: keyboard.one_time_keyboard,
    selective: keyboard.selective,
    input_field_placeholder: keyboard.input_field_placeholder,
    is_persistent: keyboard.is_persistent,
  )
}

pub fn one_time(keyboard: Keyboard) -> Keyboard {
  Keyboard(..keyboard, one_time_keyboard: Some(True))
}

pub fn persistent(keyboard: Keyboard) -> Keyboard {
  Keyboard(..keyboard, is_persistent: Some(True))
}

pub fn resized(keyboard: Keyboard) -> Keyboard {
  Keyboard(..keyboard, resize_keyboard: Some(True))
}

pub fn placeholder(keyboard: Keyboard, text: String) -> Keyboard {
  Keyboard(..keyboard, input_field_placeholder: Some(text))
}

pub fn selected(keyboard: Keyboard) -> Keyboard {
  Keyboard(..keyboard, selective: Some(True))
}

pub fn button(text: String) -> KeyboardButton {
  KeyboardButton(
    text: text,
    request_users: None,
    request_chat: None,
    request_contact: None,
    request_location: None,
    request_poll: None,
    web_app: None,
  )
}

// Inline keyboard ------------------------------------------------------------------------------------

pub opaque type InlineKeyboard {
  InlineKeyboard(buttons: List(List(InlineKeyboardButton)))
}

pub fn new_inline(buttons: List(List(InlineKeyboardButton))) -> InlineKeyboard {
  InlineKeyboard(buttons)
}

pub fn build_inline(keyboard: InlineKeyboard) -> ReplyMarkup {
  ReplyInlineKeyboardMarkup(inline_keyboard: keyboard.buttons)
}

pub fn inline_button(
  text text: String,
  callback_data callback_data: String,
) -> InlineKeyboardButton {
  InlineKeyboardButton(
    text: text,
    callback_data: Some(callback_data),
    url: None,
    login_url: None,
    pay: None,
    switch_inline_query: None,
    switch_inline_query_current_chat: None,
    switch_inline_query_chosen_chat: None,
    web_app: None,
  )
}

// Callback --------------------------------------------------------------------------------------------

pub opaque type KeyboardCallbackData(data) {
  KeyboardCallbackData(
    id: String,
    serilize: fn(data) -> String,
    deserialize: fn(String) -> data,
    delimiter: String,
  )
}

pub type KeyboardCallback(data) {
  KeyboardCallback(id: String, payload: String, data: data)
}

pub fn new_callback(
  id id: String,
  serilize serilize: fn(data) -> String,
  deserialize deserialize: fn(String) -> data,
) {
  KeyboardCallbackData(
    id: id,
    serilize: serilize,
    deserialize: deserialize,
    delimiter: ":",
  )
}

pub fn set_callback_data_delimiter(
  data: KeyboardCallbackData(data),
  delimiter: String,
) -> KeyboardCallbackData(data) {
  KeyboardCallbackData(..data, delimiter: delimiter)
}

pub fn pack_callback(
  callback_data: KeyboardCallbackData(data),
  data: data,
) -> KeyboardCallback(data) {
  let payload =
    callback_data.id <> callback_data.delimiter <> callback_data.serilize(data)

  KeyboardCallback(id: callback_data.id, payload: payload, data: data)
}

pub fn unpack_callback(
  callback_data: KeyboardCallbackData(data),
  payload: String,
) -> Result(KeyboardCallback(data), Nil) {
  use #(id, data) <- result.try(string.split_once(
    payload,
    callback_data.delimiter,
  ))

  Ok(KeyboardCallback(
    id: id,
    payload: payload,
    data: callback_data.deserialize(data),
  ))
}
