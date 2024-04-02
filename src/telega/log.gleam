import gleam/string
import logging.{Debug, Error, Info, Warning}

pub fn error(message: String) -> Nil {
  logging.log(Error, message)
}

pub fn debug(message: anything) -> Nil {
  logging.log(Debug, string.inspect(message))
}

pub fn info_d(message: anything) -> Nil {
  logging.log(Info, string.inspect(message))
}

pub fn info(message: String) -> Nil {
  logging.log(Info, message)
}

pub fn warn(message: String) -> Nil {
  logging.log(Warning, message)
}
