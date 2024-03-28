import gleam/json.{type Json}

pub type IntOrString {
  Int(Int)
  String(String)
}

pub fn string_or_int_to_json(value: IntOrString) -> Json {
  case value {
    Int(value) -> json.int(value)
    String(value) -> json.string(value)
  }
}
