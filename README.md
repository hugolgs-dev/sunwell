# sunwell

[![Package Version](https://img.shields.io/hexpm/v/sunwell)](https://hex.pm/packages/sunwell)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/sunwell/)
[![test](https://github.com/hugolgs-dev/sunwell/actions/workflows/test.yml/badge.svg)](https://github.com/hugolgs-dev/sunwell/actions/workflows/test.yml)

## What is sunwell

A Gleam package to encode & decode [Hearthstone](https://hearthstone.blizzard.com/en-us) deckstrings. 

## Status

Work-in-progress.

## Installation

```sh
gleam add sunwell
```

## Usage

```gleam
import gleam/io
import sunwell
import sunwell/deck

pub fn main() {
  let assert Ok(definition) =
    sunwell.decode("AAECAR8GxwPJBLsFmQfZB/gIDI0B2AGoArUDhwSSBe0G6wfbCe0JgQr+DAAA")

  definition.format // deck.Standard
  definition.heroes // [31]
  definition.cards  // [deck.DeckCard(141, 2), deck.DeckCard(216, 2), ..]

  let assert Ok(deckstring) = sunwell.encode(definition)
  io.println(deckstring)
}
```

Both functions return a `Result`, so malformed input is reported rather than raised:

```gleam
sunwell.decode("not a deckstring")
// -> Error(deck.InvalidDeckstring)
```

See `sunwell/deck` for `DeckDefinition`, `Format`, and the full `DeckError` type.

## Targets

Runs on both the Erlang and JavaScript targets. Pure Gleam with no FFI, and `gleam_stdlib` as the only dependency.

## Acknowledgements

This package is an adaptation in Gleam of [hearthstone_deckstrings](https://github.com/HearthSim/hearthstone-deckstrings), a JavaScript/TypeScript library with the same goal as this package.

The documentation provided [here](https://hearthsim.info/docs/deckstrings/) was of great help in understanding the deckstring format. Thanks to the HearthSim team for providing it.

## License

[MIT](LICENSE)
