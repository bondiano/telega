import session.{type Language, English, Russian}
import telega/keyboard.{type KeyboardCallbackData}

const keyboard_id = "language"

pub type LanguageInlineKeyboardData =
  KeyboardCallbackData(Language)

pub fn new_inline_keyboard(
  lang: Language,
  callback_data: LanguageInlineKeyboardData,
) {
  keyboard.new_inline([
    [
      keyboard.inline_button(
        text: t_russian_button_text(lang),
        callback_data: keyboard.pack_callback(callback_data, Russian),
      ),
      keyboard.inline_button(
        text: t_english_button_text(lang),
        callback_data: keyboard.pack_callback(callback_data, English),
      ),
    ],
  ])
}

pub fn new_keyboard(lang: Language) {
  let buttons_row = case lang {
    Russian -> [keyboard.button(t_english_button_text(lang))]
    English -> [keyboard.button(t_russian_button_text(lang))]
  }

  keyboard.new([buttons_row])
  |> keyboard.one_time
}

pub fn option_to_language(option: String) -> Language {
  case option {
    "🇷🇺 Russian" -> Russian
    "🇬🇧 Английский" -> English
    _ -> panic as "Unknown keyboard language"
  }
}

pub fn build_keyboard_callback_data() {
  keyboard.new_callback_data(
    id: keyboard_id,
    serilize: fn(data: Language) {
      case data {
        Russian -> "russian"
        English -> "english"
      }
    },
    deserialize: fn(payload: String) {
      case payload {
        "russian" -> Russian
        "english" -> English
        _ -> panic as "Unknown keyboard language"
      }
    },
  )
}

fn t_russian_button_text(lang: Language) {
  case lang {
    Russian -> "✅ 🇷🇺 Русский"
    English -> "🇷🇺 Russian"
  }
}

fn t_english_button_text(lang: Language) {
  case lang {
    Russian -> "🇬🇧 Английский"
    English -> "✅ 🇬🇧 English"
  }
}
