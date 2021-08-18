////////////////////////////////////////
// Get to know this Saga Deck Can 🃏 //
//////////////////////////////////////

// Let's start with what betadeck can do. Here's the public interface that it exposes to the world:

type BetaDeckCanister = {
    
    // Run once

    init : shared (owners : [Principal], metadata : Tarot.DeckCanMeta) -> async ([Principal], Tarot.DeckCanMeta);

    // About this can

    metadata : shared query () -> async Tarot.DeckCanMeta;

    // Tarot things

    randomizedCard : shared () -> async Tarot.RandomizedCard;
    // randomizedDeck : shared () -> async Tarot.RandomizedDeck;

    // Asset access

    // asset : shared query () -> async DlNftTypes.StaticAsset;
    http_request : shared (path : Text) -> async DlNftTypes.StaticAsset;

    // NFT things: Tarot

    nftOfOwner : shared query () -> async ();
    ownerOfNft : shared query () -> async ();

    // NFT things: Ext

    extensions : shared query () -> async [ExtCore.Extension];
    bearer : shared query (token : ExtCore.TokenIdentifier) -> async Result.Result<ExtCore.AccountIdentifier, ExtCore.CommonError>;
    mint : shared (request : ExtNonFungible.MintRequest) -> async ();
    transfer : shared (request : ExtCore.TransferRequest) -> async ExtCore.TransferResponse;

    // NFT things: Departure Labs

    // Admin: general

    canisterOwners : shared () -> async ();

    // Admin: initial setup

    assetAdmin : shared () -> async ();
    assetCheck : shared query () -> async ();
    assetLock : shared () -> async ();

    // Cycles utility

    c4Send : shared query (amount : Nat) -> async Nat;
    c4Receive : shared () -> async Nat;
    c4Query : shared () -> async Nat;
};