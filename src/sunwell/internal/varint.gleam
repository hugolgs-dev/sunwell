import gleam/int
import sunwell/deck.{type DeckError, UnexpectedEnd}

pub fn encode(value: Int) -> BitArray {
  do_encode(value, <<>>)
}

fn do_encode(value: Int, acc: BitArray) -> BitArray {
  let low = int.bitwise_and(value, 0x7f)
  let rest = int.bitwise_shift_right(value, 7)
  case rest {
    0 -> <<acc:bits, low>>
    _ -> do_encode(rest, <<acc:bits, { int.bitwise_or(low, 0x80) }>>)
  }
}

pub fn decode(bytes: BitArray) -> Result(#(Int, BitArray), DeckError) {
  do_decode(bytes, 0, 0)
}

fn do_decode(bytes, shift, acc) {
  case bytes {
    <<byte, rest:bits>> -> {
      let acc =
        int.bitwise_or(
          acc,
          int.bitwise_shift_left(int.bitwise_and(byte, 0x7f), shift),
        )
      case int.bitwise_and(byte, 0x80) {
        0 -> Ok(#(acc, rest))
        _ -> do_decode(rest, shift + 7, acc)
      }
    }
    _ -> Error(UnexpectedEnd)
  }
}
