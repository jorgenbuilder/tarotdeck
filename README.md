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


## Deploy a Deck Can

We'll be doing this using the CLI, which will require `didc`: https://github.com/dfinity/candid/releases.
Currently, the canister is initialized with the caller as the owner. This means we have to call the init method using `wallet_call`.

```zsh
dfx start --background
dfx deploy
dfx canister call $(dfx identity get-wallet) wallet_call "(record {\
    canister = principal \"$(dfx canister id tarotdeck)\";\
    method_name = \"init\";\
    cycles = (0:nat64);\
    args = $(didc encode "(
        vec {\
            principal \"$(dfx identity get-principal)\";\
        },\
        record {\
            name = \"R.W.S.\";\
            flavour = \"The traditional Tarot deck.\";\
            description = \"A basic Rider Waite Smith deck.\";\
            artists = vec {\
                \"Pamela Coleman Smith\"\
            };\
        }\
    )" -f blob);\
})"
```

This will initialize a canister with some metadata, and with your local dfx identity as an owner. Next, you'll need to provision card art to the canister:

```zsh
# Mileage will vary with this bash script. My MacOS zsh can handle up to ~250kb files, but WSL Ubuntu can't run this at all.
# TODO: A new upload script 
for file in ./art/*; dfx canister call tarotdeck assetAdmin "(record {\
    index = $(echo $file | sed -E "s/(\.\/art\/)([0-9]+)\.(webp)/\2/");\
    asset = record {\
        contentType = \"image/$(echo $file | sed -E "s/(\.\/art\/)([0-9]+)\.(webp)/\3/")\";\
        payload = vec {\
            vec { $(for byte in $(od -v -tuC $file | sed -E "s/[0-9]+//"); echo "$byte;") };\
        };\
    }\
})"
```

Mint yourself a deck:

```zsh
dfx canister call tarotdeck mint "(record { \"to\" = variant { \"address\" = \"$(dfx ledger account-id)\" }})"
```

Read the ledger:

```zsh
dfx canister call tarotdeck readLedger
```


## Donate to a canister

```shell
dfx canister call <your_wallet_canister_id> wallet_send '(record { canister = principal "<tarotdeck_canister_id>"; amount = (1_000_000_000_000:nat64); } )'
```