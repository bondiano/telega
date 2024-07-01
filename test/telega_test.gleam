import gleam/http/response.{type Response, Response}
import gleam/httpc
import gleam/option.{None}
import gleeunit
import gleeunit/should
import mockth
import telega/bot
import telega/internal/config

pub fn main() {
  gleeunit.main()
}

fn create_new_config() {
  config.new(
    token: "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11",
    url: "https://test.com",
    webhook_path: "secret",
    secret_token: None,
  )
}

fn with_mocked_httpc(resp: Response(String), wrapped: fn() -> Nil) {
  httpc.configure()
  let assert Ok(_) = mockth.expect("gleam@httpc", "send", fn(_) { Ok(resp) })
  wrapped()
  mockth.unload("gleam@httpc")
}

pub fn set_webhook_test() {
  use <- with_mocked_httpc(Response(200, [], "{\"ok\": true, \"result\": true}"))

  create_new_config()
  |> bot.set_webhook()
  |> should.equal(Ok(True))
}
