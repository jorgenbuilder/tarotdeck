# The Universal Digital Tarot Deck Software Canister 🌏🃏 `BETA`

This is an open source software canister deployable to the Internet Computer that models a traditional Tarot card deck as a digital asset. This canister exists to:

1. Provide the elementary functionality of a full deck of Tarot cards, being as faithful as possible to the spirit of Tarot.
2. Provide the Tarot community and developers with an easy-to-use standard for a deck of Tarot cards that can be used for any arbitrary purpose.
3. Provide all of the functionality required for a trustless/permissionless economy of Tarot decks as digital goods, including ownership and transfer of individual copies of a deck (compatibility with token standards and community marketplaces,) and creation and ownership of Tarot card decks, of which many individual copies can be minted.


## Interacting With a Tarot Deck Canister

The deck canister strives to expose all functionality through both Https and Candid interfaces.


## Elementary Functionality

**Users can fetch art for all 78 cards in a traditional deck, plus two card backs.** Via Https: `https://<canister-id>.ic0.raw.app/card-art/<0-79>/`. Via Candid: `asset(index : Nat)`. This will return the payload of an image asset as a `Blob` and the content type for the image asset.    

**Users can fetch basic information for all 78 cards in a traditional deck.** Basic information for each card includes:

- `index`: 0-79 index of the card, where `78` and `79` are the card back art, and the alternate card back art.
- `name`: The name of the Tarot card (ex: "The Fool".)
- `number`: The number of the Tarot card within its suit.
- `suit`: The suit of the tarot card: trump, cups, pentacles, wands, swords.

See [the data]().    

**Users can fetch a randomized card from the deck.** This will return the basic information (see above) for a random card, plus an orientation (reversed or upright.) Via Https: `https://<canister-id>.ic0.raw.app/card-info/<0-77>/`. Via Candid: `cardInfo(index : Nat)`.

**Creators can deploy a new deck canister, provision it with art and metadata and launch it into the Tarot and IC NFT ecosystems.** TODO: make a creator's readme.


## What Can I Do With a Deck?

The intention is that an owner of an individual deck can plug it in to many different digital experiences. In practice today, decks can be used in Saga's single card readings: https://l2jyf-nqaaa-aaaah-qadha-cai.raw.ic0.app/.


## Open Development

This repository, like the Saga project as a whole, is open to PRs and general contributions. The goal is to turn this project into a tokenized open business.


## Roadmap

- [ ] Saga decks can be listed on Toniq's marketplace (adhere to EXT standard.)
- [ ] Deck canisters can be discovered arbitrarily using a common Typescript interface.
- [ ] Deck canisters can be queried for ownership to restrict use of the deck using a common Typescript interface.
- [ ] Deck canisters can serve a randomized entire deck (i.e. randomized [0-77] cards).
- [ ] Admins can configure the rate at which reversed card draws occur.
- [ ] Image assets served over Https should be given a very long-lived expire header if the canister is in production mode.
