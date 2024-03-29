import gleam/option.{type Option}
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

pub fn option_to_json_object_list(
  value value: Option(a),
  field field: String,
  encoder encoder: fn(a) -> Json,
) -> List(#(String, Json)) {
  option.map(value, fn(v) { [#(field, encoder(v))] })
  |> option.unwrap([])
}
