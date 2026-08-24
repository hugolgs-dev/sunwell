import gleam/bit_array
import gleam/int
import gleam/list
import gleam/order
import gleam/result
import sunwell/deck.{type DeckDefinition, type DeckError}
import sunwell/internal/varint

/// decode: decodes a deckstring into a [`DeckDefinition`].
pub fn decode(deckstring: String) -> Result(DeckDefinition, DeckError) {
  use bytes <- result.try(
    bit_array.base64_decode(deckstring)
    |> result.replace_error(deck.InvalidDeckstring),
  )
  use rest <- result.try(expect_leading_zero(bytes))

  use #(version, rest) <- result.try(varint.decode(rest))
  use _ <- result.try(case version == deck.deckstring_version {
    True -> Ok(Nil)
    False -> Error(deck.InvalidVersion(version))
  })

  use #(format_int, rest) <- result.try(varint.decode(rest))
  use format <- result.try(deck.format_from_int(format_int))

  use #(heroes, rest) <- result.try(read_list(rest, varint.decode))

  use #(singles, rest) <- result.try(read_list(rest, card(1)))
  use #(doubles, rest) <- result.try(read_list(rest, card(2)))
  use #(multi, rest) <- result.try(read_list(rest, n_copy_card))

  let cards =
    list.flatten([singles, doubles, multi])
    |> list.sort(by_dbf_id)

  use sideboard_cards <- result.try(read_sideboard(rest))

  Ok(deck.DeckDefinition(format:, heroes:, cards:, sideboard_cards:))
}

fn expect_leading_zero(bytes: BitArray) -> Result(BitArray, DeckError) {
  case bytes {
    <<0, rest:bits>> -> Ok(rest)
    _ -> Error(deck.InvalidDeckstring)
  }
}

fn read_sideboard(
  bytes: BitArray,
) -> Result(List(deck.SideboardCard), DeckError) {
  case bytes {
    <<>> -> Ok([])
    <<0, _:bits>> -> Ok([])
    <<1, rest:bits>> -> {
      use #(singles, rest) <- result.try(read_list(rest, sideboard_card(1)))
      use #(doubles, rest) <- result.try(read_list(rest, sideboard_card(2)))
      use #(multi, _rest) <- result.try(read_list(rest, n_copy_sideboard_card))

      Ok(
        list.flatten([singles, doubles, multi])
        |> list.sort(by_owner_then_dbf_id),
      )
    }
    _ -> Error(deck.InvalidDeckstring)
  }
}

fn read_list(
  bytes: BitArray,
  read: fn(BitArray) -> Result(#(a, BitArray), DeckError),
) -> Result(#(List(a), BitArray), DeckError) {
  use #(count, rest) <- result.try(varint.decode(bytes))
  do_read_n(rest, count, read, [])
}

fn do_read_n(
  bytes: BitArray,
  count: Int,
  read: fn(BitArray) -> Result(#(a, BitArray), DeckError),
  acc: List(a),
) -> Result(#(List(a), BitArray), DeckError) {
  case count <= 0 {
    True -> Ok(#(list.reverse(acc), bytes))
    False -> {
      use #(value, rest) <- result.try(read(bytes))
      do_read_n(rest, count - 1, read, [value, ..acc])
    }
  }
}

fn card(
  copies: Int,
) -> fn(BitArray) -> Result(#(deck.DeckCard, BitArray), DeckError) {
  fn(bytes) {
    use #(dbf_id, rest) <- result.try(varint.decode(bytes))
    Ok(#(deck.DeckCard(dbf_id, copies), rest))
  }
}

fn n_copy_card(
  bytes: BitArray,
) -> Result(#(deck.DeckCard, BitArray), DeckError) {
  use #(dbf_id, rest) <- result.try(varint.decode(bytes))
  use #(count, rest) <- result.try(varint.decode(rest))
  Ok(#(deck.DeckCard(dbf_id, count), rest))
}

fn sideboard_card(
  copies: Int,
) -> fn(BitArray) -> Result(#(deck.SideboardCard, BitArray), DeckError) {
  fn(bytes) {
    use #(dbf_id, rest) <- result.try(varint.decode(bytes))
    use #(owner, rest) <- result.try(varint.decode(rest))
    Ok(#(deck.SideboardCard(dbf_id, copies, owner), rest))
  }
}

fn n_copy_sideboard_card(
  bytes: BitArray,
) -> Result(#(deck.SideboardCard, BitArray), DeckError) {
  use #(dbf_id, rest) <- result.try(varint.decode(bytes))
  use #(count, rest) <- result.try(varint.decode(rest))
  use #(owner, rest) <- result.try(varint.decode(rest))
  Ok(#(deck.SideboardCard(dbf_id, count, owner), rest))
}

fn by_dbf_id(a: deck.DeckCard, b: deck.DeckCard) -> order.Order {
  int.compare(a.dbf_id, b.dbf_id)
}

fn trisort(
  items: List(a),
  count: fn(a) -> Int,
) -> #(List(a), List(a), List(a)) {
  let #(singles, rest) = list.partition(items, fn(item) { count(item) == 1 })
  let #(doubles, multi) = list.partition(rest, fn(item) { count(item) == 2 })
  #(singles, doubles, multi)
}

fn append_block(
  acc: BitArray,
  items: List(a),
  write: fn(BitArray, a) -> BitArray,
) -> BitArray {
  list.fold(items, append_varint(acc, list.length(items)), write)
}

fn by_owner_then_dbf_id(
  a: deck.SideboardCard,
  b: deck.SideboardCard,
) -> order.Order {
  int.compare(a.sideboard_owner_dbf_id, b.sideboard_owner_dbf_id)
  |> order.lazy_break_tie(fn() { int.compare(a.dbf_id, b.dbf_id) })
}

/// encode: encodes a [`DeckDefinition`] into a deckstring.
pub fn encode(definition: DeckDefinition) -> Result(String, DeckError) {
  let deck.DeckDefinition(cards:, sideboard_cards:, heroes:, format:) =
    definition

  use _ <- result.try(
    list.try_each(heroes, fn(hero) { positive(hero, deck.InvalidHero) }),
  )
  use _ <- result.try(
    list.try_each(cards, fn(card) {
      use _ <- result.try(positive(card.dbf_id, deck.InvalidCard))
      positive(card.count, deck.InvalidCardCount)
    }),
  )
  use _ <- result.try(
    list.try_each(sideboard_cards, fn(card) {
      use _ <- result.try(positive(card.dbf_id, deck.InvalidCard))
      use _ <- result.try(positive(card.count, deck.InvalidSideboardCardCount))
      positive(card.sideboard_owner_dbf_id, deck.InvalidSideboardOwner)
    }),
  )

  let #(singles, doubles, multiples) =
    list.sort(cards, by_dbf_id)
    |> trisort(fn(card) { card.count })
  let heroes = list.sort(heroes, int.compare)

  let dbf_id = fn(acc, card: deck.DeckCard) { append_varint(acc, card.dbf_id) }

  let bytes =
    <<0>>
    |> append_varint(deck.deckstring_version)
    |> append_varint(deck.format_to_int(format))
    |> append_block(heroes, append_varint)
    |> append_block(singles, dbf_id)
    |> append_block(doubles, dbf_id)
    |> append_block(multiples, fn(acc, card: deck.DeckCard) {
      acc |> append_varint(card.dbf_id) |> append_varint(card.count)
    })
    |> append_sideboard(sideboard_cards)

  Ok(bit_array.base64_encode(bytes, True))
}

fn positive(value: Int, error: fn(Int) -> DeckError) -> Result(Nil, DeckError) {
  case value > 0 {
    True -> Ok(Nil)
    False -> Error(error(value))
  }
}

fn append_varint(acc: BitArray, value: Int) -> BitArray {
  <<acc:bits, varint.encode(value):bits>>
}

fn append_sideboard(
  acc: BitArray,
  cards: List(deck.SideboardCard),
) -> BitArray {
  case cards {
    [] -> append_varint(acc, 0)
    _ -> {
      let #(singles, doubles, multiples) =
        list.sort(cards, by_owner_then_dbf_id)
        |> trisort(fn(card) { card.count })

      let pair = fn(acc, card: deck.SideboardCard) {
        acc
        |> append_varint(card.dbf_id)
        |> append_varint(card.sideboard_owner_dbf_id)
      }

      acc
      |> append_varint(1)
      |> append_block(singles, pair)
      |> append_block(doubles, pair)
      |> append_block(multiples, fn(acc, card: deck.SideboardCard) {
        acc
        |> append_varint(card.dbf_id)
        |> append_varint(card.count)
        |> append_varint(card.sideboard_owner_dbf_id)
      })
    }
  }
}
