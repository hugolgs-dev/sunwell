import gleeunit
import sunwell
import sunwell/deck
import sunwell/internal/varint

pub fn main() {
  gleeunit.main()
}

pub fn varint_encode_test() {
  assert varint.encode(0) == <<0>>
  assert varint.encode(1) == <<1>>
  assert varint.encode(127) == <<127>>
  assert varint.encode(128) == <<0x80, 0x01>>
  assert varint.encode(300) == <<0xAC, 0x02>>
}

pub fn varint_decode_test() {
  assert varint.decode(<<0xAC, 0x02>>) == Ok(#(300, <<>>))
  assert varint.decode(<<>>) == Error(deck.UnexpectedEnd)
}

pub fn varint_cycle_test() {
  assert varint.decode(varint.encode(123_456)) == Ok(#(123_456, <<>>))
}

pub fn decode_deckstring_test() {
  let deckstring = "AAEBAQcAAAQBAwIDAwMEAwA="

  let expected =
    deck.DeckDefinition(
      format: deck.Wild,
      heroes: [7],
      cards: [
        deck.DeckCard(1, 3),
        deck.DeckCard(2, 3),
        deck.DeckCard(3, 3),
        deck.DeckCard(4, 3),
      ],
      sideboard_cards: [],
    )

  assert sunwell.decode(deckstring) == Ok(expected)
}

pub fn encode_deckstring_test() {
  let deck_def =
    deck.DeckDefinition(
      format: deck.Wild,
      heroes: [7],
      cards: [
        deck.DeckCard(1, 3),
        deck.DeckCard(2, 3),
        deck.DeckCard(3, 3),
        deck.DeckCard(4, 3),
      ],
      sideboard_cards: [],
    )

  assert sunwell.encode(deck_def) == Ok("AAEBAQcAAAQBAwIDAwMEAwA=")
}

pub fn encode_sorts_test() {
  let deck_def =
    deck.DeckDefinition(
      format: deck.Wild,
      heroes: [7],
      cards: [
        deck.DeckCard(3, 3),
        deck.DeckCard(2, 3),
        deck.DeckCard(1, 3),
        deck.DeckCard(4, 3),
      ],
      sideboard_cards: [],
    )

  assert sunwell.encode(deck_def) == Ok("AAEBAQcAAAQBAwIDAwMEAwA=")
}

pub fn encode_decode_cycle_test() {
  let deck_def =
    deck.DeckDefinition(
      format: deck.Standard,
      heroes: [7],
      cards: [deck.DeckCard(1, 1), deck.DeckCard(2, 2), deck.DeckCard(3, 3)],
      sideboard_cards: [],
    )

  let assert Ok(deckstring) = sunwell.encode(deck_def)
  assert sunwell.decode(deckstring) == Ok(deck_def)
}

pub fn canonical_roundtrip_test() {
  let deckstring =
    "AAECAR8GxwPJBLsFmQfZB/gIDI0B2AGoArUDhwSSBe0G6wfbCe0JgQr+DAAA"
  let assert Ok(definition) = sunwell.decode(deckstring)
  assert sunwell.encode(definition) == Ok(deckstring)
}

pub fn sideboard_roundtrip_test() {
  let deckstring =
    "AAEBAZCaBgjlsASotgSX7wTvkQXipAX9xAXPxgXGxwUQvp8EobYElrcE+dsEuNwEutwE9vAEhoMFopkF4KQFlMQFu8QFu8cFuJ4Gz54G0Z4GAAED8J8E/cQFuNkE/cQF/+EE/cQFAAA="

  let assert Ok(definition) = sunwell.decode(deckstring)

  assert definition.sideboard_cards
    == [
      deck.SideboardCard(69_616, 1, 90_749),
      deck.SideboardCard(76_984, 1, 90_749),
      deck.SideboardCard(78_079, 1, 90_749),
    ]

  assert sunwell.encode(definition) == Ok(deckstring)
}

pub fn encode_rejects_invalid_card_test() {
  let with_cards = fn(cards) {
    deck.DeckDefinition(
      format: deck.Wild,
      heroes: [7],
      cards:,
      sideboard_cards: [],
    )
  }

  assert sunwell.encode(with_cards([deck.DeckCard(-1, 1)]))
    == Error(deck.InvalidCard(-1))
  assert sunwell.encode(with_cards([deck.DeckCard(1, 0)]))
    == Error(deck.InvalidCardCount(0))
}

pub fn encode_rejects_invalid_hero_test() {
  let definition =
    deck.DeckDefinition(
      format: deck.Wild,
      heroes: [-7],
      cards: [],
      sideboard_cards: [],
    )

  assert sunwell.encode(definition) == Error(deck.InvalidHero(-7))
}

pub fn encode_rejects_invalid_sideboard_owner_test() {
  let definition =
    deck.DeckDefinition(
      format: deck.Wild,
      heroes: [7],
      cards: [deck.DeckCard(1, 1)],
      sideboard_cards: [deck.SideboardCard(1, 1, 0)],
    )

  assert sunwell.encode(definition) == Error(deck.InvalidSideboardOwner(0))
}

pub fn varint_rejects_long_chain_test() {
  let eight_bytes = <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01>>
  assert varint.decode(eight_bytes) == Error(deck.UnexpectedEnd)

  let seven_bytes_max = <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>
  assert varint.decode(seven_bytes_max) == Ok(#(562_949_953_421_311, <<>>))
}
