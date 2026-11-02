# sunwell

[![Package Version](https://img.shields.io/hexpm/v/sunwell)](https://hex.pm/packages/sunwell)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/sunwell/)
[![test](https://github.com/hugolgs-dev/sunwell/actions/workflows/test.yml/badge.svg)](https://github.com/hugolgs-dev/sunwell/actions/workflows/test.yml)

A Gleam package to encode & decode [Hearthstone](https://hearthstone.blizzard.com/en-us) deckstrings. 

## Installation

```sh
gleam add sunwell
```

## Usage

```gleam
import gleam/io
import sunwell
import sunwell/deck

const deckstring = "AAECAR8GxwPJBLsFmQfZB/gIDI0B2AGoArUDhwSSBe0G6wfbCe0JgQr+DAAA"

pub fn main() {
  let assert Ok(definition) = sunwell.decode(deckstring)

  let assert deck.Standard = definition.format
  let assert [31] = definition.heroes
  echo definition.cards

  let assert Ok(encoded) = sunwell.encode(definition)
  let assert True = encoded == deckstring
  io.println(encoded)

  let assert Error(deck.InvalidDeckstring) = sunwell.decode("not a deckstring")
}
```

Output:

```sh
[DeckCard(141, 2), DeckCard(216, 2), DeckCard(296, 2), DeckCard(437, 2), DeckCard(455, 1), DeckCard(519, 2), DeckCard(585, 1), DeckCard(658, 2), DeckCard(699, 1), DeckCard(877, 2), DeckCard(921, 1), DeckCard(985, 1), DeckCard(1003, 2), DeckCard(1144, 1), DeckCard(1243, 2), DeckCard(1261, 2), DeckCard(1281, 2), DeckCard(1662, 2)]
AAECAR8GxwPJBLsFmQfZB/gIDI0B2AGoArUDhwSSBe0G6wfbCe0JgQr+DAAA
```

See `sunwell/deck` for `DeckDefinition`, `Format`, and the full `DeckError` type.

## Targets

Runs on both the Erlang and JavaScript targets. Pure Gleam with no FFI, and `gleam_stdlib` as the only dependency.

## Acknowledgements

This package is an adaptation in Gleam of [hearthstone_deckstrings](https://github.com/HearthSim/hearthstone-deckstrings), a JavaScript/TypeScript library with the same goal as this package.

The documentation provided [here](https://hearthsim.info/docs/deckstrings/) was of great help in understanding the deckstring format. Thanks to the HearthSim team for providing it.

## License

[MIT](LICENSE)
