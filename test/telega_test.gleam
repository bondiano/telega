import gleeunit
import gleeunit/should
import telega
import gleam/http.{Post}
import wisp/testing

pub fn main() {
  gleeunit.main()
}

fn create_new_bot() {
  telega.new(
    token: "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11",
    url: "https://test.com",
    secret: "secret",
  )
}

pub fn is_bot_request_test() {
  let request = testing.request(Post, "/secret", [], <<>>)

  create_new_bot()
  |> telega.is_bot_request(request)
  |> should.equal(True)
}
