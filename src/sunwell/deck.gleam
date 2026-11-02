//// Deck definitions, rules and errors live here.

/// Format of the deck, used to determine which cards are legal in it.
pub type Format {
  Wild
  Standard
  Classic
  Twist
}

/// Main deck card type, used to represent a card in the deck and its number of copies.
pub type DeckCard {
  /// dbf_id of the card and its number of copies.
  DeckCard(dbf_id: Int, count: Int)
}

/// For cards using a sideboard (E.T.C, Zilliax, etc)
pub type SideboardCard {
  /// dbf_id of the card, its number of copies, and the dbf_id of the card that owns the sideboard.
  SideboardCard(dbf_id: Int, count: Int, sideboard_owner_dbf_id: Int)
}

/// Decoded deck / input for encoding a deckstring. Contains the cards, sideboard cards, heroes, and format of the deck.
pub type DeckDefinition {
  /// The whole deck definition, including the cards, sideboard cards, heroes, and format.
  DeckDefinition(
    /// Main deck cards, each with their dbf_id and number of copies.
    cards: List(DeckCard),
    /// Sideboard cards, each with their dbf_id, number of copies, and the dbf_id of the card that owns the sideboard.
    sideboard_cards: List(SideboardCard),
    /// Hero of the deck, represented by their dbf_id.
    heroes: List(Int),
    /// Format of the deck (Standard, Wild, Classic, or Twist), used to determine which cards are legal in it.
    format: Format,
  )
}

/// All the errors possible when encoding/decoding a deckstring.
pub type DeckError {
  /// Card's dbf_id doesn't exist so it's an invalid card.
  InvalidCard(dbf_id: Int)
  /// Unknown format number (not 1, 2, 3 or 4).
  InvalidFormat(format: Int)
  /// Hero's dbf_id doesn't exist so it's an invalid hero.
  InvalidHero(hero: Int)
  /// Invalid base64, header and/or malformed bytes.
  InvalidDeckstring
  /// The number of cards in the deck is invalid.
  InvalidCardCount(count: Int)
  /// The sideboard owner's dbf_id doesn't exist so it's an invalid sideboard owner.
  InvalidSideboardOwner(owner: Int)
  /// The number of sideboard cards in the deck is invalid.
  InvalidSideboardCardCount(count: Int)
  /// The version number in the deckstring is invalid. (Not equal to deckstring_version basically.)
  InvalidVersion(version: Int)
  /// Bytes ran out in the middle of a varint, so the deckstring is truncated.
  UnexpectedEnd
}

/// Every Hearthstone deckstring starts with a small header, and one byte of that
/// header is a format version number. From what I found, Blizzard has only ever used
/// 1. The code uses this constant in two places:
/// - when encoding a deckstring, it writes this number to the header
/// - when decoding a deckstring, it checks that the number in the header is equal to this constant.
/// If it's not, it returns an `InvalidVersion` error.
pub const deckstring_version = 1

/// Format -> Number stored in the deckstring.
pub fn format_to_int(format: Format) -> Int {
  case format {
    Wild -> 1
    Standard -> 2
    Classic -> 3
    Twist -> 4
  }
}

/// deckstring number -> Format of the deckstring. InvalidFormat if it's invalid (not 1, 2, 3 or 4).
pub fn format_from_int(value: Int) -> Result(Format, DeckError) {
  case value {
    1 -> Ok(Wild)
    2 -> Ok(Standard)
    3 -> Ok(Classic)
    4 -> Ok(Twist)
    _ -> Error(InvalidFormat(value))
  }
}
