import carpenter/table
import telega

pub type NameBotState {
  SetName
  WaitName
}

pub type NameBotSession {
  NameBotSession(name: String, state: NameBotState)
}

pub fn attach(bot) {
  let assert Ok(session_table) =
    table.build("session")
    |> table.privacy(table.Public)
    |> table.set

  telega.with_session_settings(
    bot,
    get_session: fn(key) {
      case table.lookup(session_table, key) {
        [#(_, session), ..] -> Ok(session)
        _ -> Ok(NameBotSession(name: "Unknown", state: WaitName))
      }
    },
    persist_session: fn(key, session) {
      table.insert(session_table, [#(key, session)])
      Ok(session)
    },
  )
}
