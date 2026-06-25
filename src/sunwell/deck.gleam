/// Deck definitions live here
pub type Format {
  Wild
  Standard
}

pub type DeckCard {
  DeckCard(dbf_id: Int, count: Int)
}

pub type SideboardCard {
  SideboardCard(dbf_id: Int, count: Int, sideboard_owner_dbf_id: Int)
}

pub type DeckDefinition {
  DeckDefinition(
    cards: List(DeckCard),
    sideboard_cards: List(SideboardCard),
    heroes: List(Int),
    format: Format,
  )
}

pub type DeckError {
  InvalidFormat(format: Int)
  InvalidHero(hero: Int)
  InvalidDeckstring
  InvalidCardCount(count: Int)
  InvalidSideboardCount(count: Int)
  InvalidSideboardOwner(owner: Int)
  InvalidSideboardCardCount(count: Int)
  InvalidVersion(version: Int)
  UnexpectedEnd
}

pub const deckstring_version = 1

pub fn format_to_int(format: Format) -> Int {
  case format {
    Wild -> 1
    Standard -> 2
  }
}

pub fn format_from_int(value: Int) -> Result(Format, DeckError) {
  case value {
    1 -> Ok(Wild)
    2 -> Ok(Standard)
    _ -> Error(InvalidFormat(value))
  }
}
