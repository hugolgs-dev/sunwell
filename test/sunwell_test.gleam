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
  let deckstring = "AAEBAQcAAAQBAwIDAwMEAw=="

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

  assert sunwell.encode(deck_def) == "AAEBAQcAAAQBAwIDAwMEAw=="
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

  assert sunwell.encode(deck_def) == "AAEBAQcAAAQBAwIDAwMEAw=="
}

pub fn encode_decode_cycle_test() {
  let deck_def =
    deck.DeckDefinition(
      format: deck.Standard,
      heroes: [7],
      cards: [deck.DeckCard(1, 1), deck.DeckCard(2, 2), deck.DeckCard(3, 3)],
      sideboard_cards: [],
    )

  assert sunwell.decode(sunwell.encode(deck_def)) == Ok(deck_def)
}
