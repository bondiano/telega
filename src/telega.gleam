import gleam/string
import gleam/result
import telega/log
import telega/bot.{type Context}

/// Log the message and error message if the handler fails.
pub fn log_context(
  ctx: Context,
  prefix: String,
  handler: fn() -> Result(Nil, String),
) -> Result(Nil, Nil) {
  let prefix = "[" <> prefix <> "] "

  log.info(prefix <> "Received message: " <> string.inspect(ctx.message.raw))

  handler()
  |> result.map_error(fn(e) {
    log.error(prefix <> "failed: " <> string.inspect(e))
  })
}
