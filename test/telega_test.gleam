import gleeunit
import gleeunit/should
import telega
import telega/adapters/wisp as telega_wisp
import gleam/http.{Post}
import gleam/http/response.{type Response, Response}
import gleam/option.{None}
import wisp/testing
import mockth
import gleam/httpc

pub fn main() {
  gleeunit.main()
}

fn create_new_bot() {
  telega.new(
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

pub fn is_bot_request_test() {
  let request = testing.request(Post, "/secret", [], <<>>)

  create_new_bot()
  |> telega_wisp.is_bot_request(request)
  |> should.equal(True)
}

pub fn set_webhook_test() {
  use <- with_mocked_httpc(Response(200, [], "{\"ok\": true, \"result\": true}"))

  create_new_bot()
  |> telega.set_webhook()
  |> should.equal(Ok(True))
}
