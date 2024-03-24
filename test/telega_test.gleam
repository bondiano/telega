import gleeunit
import gleeunit/should
import telega
import telega/adapters/wisp as telega_wisp
import gleam/http.{Post}
import gleam/option.{None}
import wisp/testing

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

pub fn is_bot_request_test() {
  let request = testing.request(Post, "/secret", [], <<>>)

  create_new_bot()
  |> telega_wisp.is_bot_request(request)
  |> should.equal(True)
}
