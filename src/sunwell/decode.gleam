import gleam/bit_array
import gleam/list
import gleam/result
import sunwell/deck.{type DeckDefinition, type DeckError}
import sunwell/internal/varint

pub fn decode(deckstring: String) -> Result(DeckDefinition, DeckError) {
  use bytes <- result.try(
    bit_array.base64_decode(deckstring)
    |> result.replace_error(deck.InvalidDeckstring),
  )
  use rest <- result.try(expect_byte(bytes, 0))

  use #(version, rest) <- result.try(varint.decode(rest))
  use _ <- result.try(case version == deck.deckstring_version {
    True -> Ok(Nil)
    False -> Error(deck.InvalidVersion(version))
  })

  use #(format_int, rest) <- result.try(varint.decode(rest))
  use format <- result.try(deck.format_from_int(format_int))

  use #(hero_count, rest) <- result.try(varint.decode(rest))
  use #(heroes, rest) <- result.try(read_varints(rest, hero_count, []))

  use #(singles, rest) <- result.try(read_card_block(rest, 1))
  use #(doubles, rest) <- result.try(read_card_block(rest, 2))

  use #(multi, _rest) <- result.try(read_n_block(rest))

  let cards = list.flatten([singles, doubles, multi])
  Ok(deck.DeckDefinition(format:, heroes:, cards:, sideboard_cards: []))
}

fn expect_byte(bytes: BitArray, expected: Int) -> Result(BitArray, DeckError) {
  case bytes {
    <<b, rest:bits>> if b == expected -> Ok(rest)
    _ -> Error(deck.InvalidDeckstring)
  }
}

fn read_varints(
  bytes: BitArray,
  count: Int,
  acc: List(Int),
) -> Result(#(List(Int), BitArray), DeckError) {
  case count {
    0 -> Ok(#(list.reverse(acc), bytes))
    _ -> {
      use #(value, rest) <- result.try(varint.decode(bytes))
      read_varints(rest, count - 1, [value, ..acc])
    }
  }
}

fn read_card_block(
  bytes: BitArray,
  copies: Int,
) -> Result(#(List(deck.DeckCard), BitArray), DeckError) {
  use #(n, rest) <- result.try(varint.decode(bytes))
  read_cards(rest, n, copies, [])
}

fn read_cards(bytes, remaining, copies, acc) {
  case remaining {
    0 -> Ok(#(list.reverse(acc), bytes))
    _ -> {
      use #(dbf_id, rest) <- result.try(varint.decode(bytes))
      read_cards(rest, remaining - 1, copies, [
        deck.DeckCard(dbf_id, copies),
        ..acc
      ])
    }
  }
}

fn read_n_block(
  bytes: BitArray,
) -> Result(#(List(deck.DeckCard), BitArray), DeckError) {
  use #(n, rest) <- result.try(varint.decode(bytes))
  read_n_cards(rest, n, [])
}

fn read_n_cards(bytes, remaining, acc) {
  case remaining {
    0 -> Ok(#(list.reverse(acc), bytes))
    _ -> {
      use #(dbf_id, rest) <- result.try(varint.decode(bytes))
      use #(count, rest2) <- result.try(varint.decode(rest))
      read_n_cards(rest2, remaining - 1, [deck.DeckCard(dbf_id, count), ..acc])
    }
  }
}
