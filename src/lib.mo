/*
 *    _____                      ____            __      ______            _      __           
 *   / ___/____ _____ _____ _   / __ \___  _____/ /__   / ____/___ _____  (_)____/ /____  _____
 *   \__ \/ __ `/ __ `/ __ `/  / / / / _ \/ ___/ //_/  / /   / __ `/ __ \/ / ___/ __/ _ \/ ___/
 *  ___/ / /_/ / /_/ / /_/ /  / /_/ /  __/ /__/ ,<    / /___/ /_/ / / / / (__  ) /_/  __/ /    
 * /____/\__,_/\__, /\__,_/  /_____/\___/\___/_/|_|   \____/\__,_/_/ /_/_/____/\__/\___/_/     
 *            /____/                                                                           
 * 
 * Version: BETADECK
 *
 * • Each deck canister represents a class of Tarot deck (ex: R.W.S., each unique hackathon deck, etc.).
 * • Provides NFT functionality that allows users to express ownership of their decks (one can tracks all user ownerships of the deck it represents.)
 *  • Uses the EXT token standard, because we want to interoperate with Toniq's services.
 *  • Uses a bunch of useful things from the Departure Labs NFT, too.
 * • Stores and serves the deck's unique image assets that make up a Tarot deck.
 * • Provides adminstrative functionality for the intial setup of a deck (provisioning your beautiful deck art!)
 * • Performs random card draws.
 * • TODO: Provides a basic frontend that allows you to use your deck to do Tarot.
 * • TODO: Provides a frontend that allows you to perform initial administrative setup.
 * • TODO: Provides an interface to allow minting decks in unlimited or limited runs.
 */


import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Random "mo:base/Random";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Text "mo:base/Text";

import DlNft "mo:dl-nft/main";
import DlNftTypes "mo:dl-nft/types";
import DlNftHttp "mo:dl-nft/httpTypes";
import ExtCore "mo:ext/Core";
import ExtNonFungible "mo:ext/NonFungible";
import ExtAccountId "mo:ext/util/AccountIdentifier";

import C4 "mo:c4";
import Tarot "./types/tarot";
import TarotData "./data/tarot";


////////////////////////////
// BETADECK CONTRACT 📜 //
/////////////////////////

shared ({ caller = creator }) actor class BetaDeck() = canister {


    /////////////////////
    // Internal State //
    ///////////////////


    // These are the EXT standard extensions that we're trying to adhere to. The goal is to be listable in NFT marketplaces.
    let EXTENSIONS = ["@ext/core, @ext/non-fungible"];

    stable var INITIALIZED : Bool = false;
    stable var METADATA : Tarot.DeckCanMeta = {
        name = "Uninitialized";
        symbol = "🥚";
        description = "";
        artists = [];
    };
    stable var OWNERS : [Principal] = [creator];
    stable var LOCKED : Bool = false;

    // We store the next token ID, which just keeps iterating forward
    stable var NEXT_ID : ExtCore.TokenIndex = 0;

    // The ledger of NFT ownerships for this deck. We key off EXT token indexes because that makes it simple to adhere to the standard.
    stable var stableLedger : [(ExtCore.TokenIndex, ExtCore.AccountIdentifier)] = [];
    var LEDGER : HashMap.HashMap<ExtCore.TokenIndex, ExtCore.AccountIdentifier> = HashMap.fromIter(stableLedger.vals(), 0, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);

    stable let ASSETS : [var ?DlNftTypes.StaticAsset] = Array.init<?DlNftTypes.StaticAsset>(80, null);

    system func preupgrade() {
        stableLedger := Iter.toArray(LEDGER.entries());
    };

    system func postupgrade() {
        stableLedger := [];
    };


    ///////////////////////
    // Public Interface //
    /////////////////////


    // A canister must be initialized with its owners and initial data before it can be used.
    public shared ({caller}) func init (owners : [Principal], metadata : Tarot.DeckCanMeta) : async ([Principal], Tarot.DeckCanMeta) {
        assert not INITIALIZED and caller == OWNERS[0];
        OWNERS := Array.append(OWNERS, owners);
        METADATA := metadata;
        INITIALIZED := true;
        (OWNERS, METADATA);
    };

    // Return basic information describing this canister and the deck that it represents.
    public shared query func metadata () : async Tarot.DeckCanMeta {
        METADATA;
    };


    /////////////////
    // Shared EXT //
    ///////////////


    // Ext standard: list available extensions
    public shared query func extensions () : async [ExtCore.Extension] {
        EXTENSIONS;
    };

    // Ext standard: get balance
    public shared query func balance (request : ExtCore.BalanceRequest) : async ExtCore.BalanceResponse {
        if (not ExtCore.TokenIdentifier.isPrincipal(request.token, Principal.fromActor(canister))) {
            return #err(#InvalidToken(request.token));
        };
        let token = ExtCore.TokenIdentifier.getIndex(request.token);
        let aid = ExtCore.User.toAID(request.user);
        switch (LEDGER.get(token)) {
            case (?owner) {
                if (ExtAccountId.equal(aid, owner)) return #ok(1);
                return #ok(0);
            };
            case Null #err(#InvalidToken(request.token));
        };
    };

    // Ext standard: transfer owner
    public shared ({ caller }) func transfer (request : ExtCore.TransferRequest) : async ExtCore.TransferResponse {
        if (request.amount != 1) {
            return #err(#Other("Only logical transfer amount for an NFT is 1, got" # Nat.toText(request.amount) # "."));
        };
        if (not ExtCore.TokenIdentifier.isPrincipal(request.token, Principal.fromActor(canister))) {
            return #err(#InvalidToken(request.token));
        };
        let token = ExtCore.TokenIdentifier.getIndex(request.token);
        let owner = ExtCore.User.toAID(request.from);
        let agent = ExtAccountId.fromPrincipal(caller, request.subaccount);
        let recipient = ExtCore.User.toAID(request.to);
        switch (LEDGER.get(token)) {
            case (?tokenOwner) {
                if (ExtAccountId.equal(owner, tokenOwner) and ExtAccountId.equal(owner, agent)) {
                    LEDGER.put(token, recipient);
                    return #ok(request.amount);
                };
                #err(#Unauthorized(owner));
            };
            case Null return #err(#InvalidToken(request.token));
        };
    };

    // Ext standard: get bearer of token
    public shared query func bearer (token : ExtCore.TokenIdentifier) : async Result.Result<ExtCore.AccountIdentifier, ExtCore.CommonError> {
        if (not ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(canister))) {
            return #err(#InvalidToken(token));
        };
        let i = ExtCore.TokenIdentifier.getIndex(token);
        switch (LEDGER.get(i)) {
            case (?owner) #ok(owner);
            case Null #err(#InvalidToken(token));
        };
    };

    // Ext standard: mint an NFT
    public shared ({ caller }) func mint (request : ExtNonFungible.MintRequest) : async () {
        assert _isOwner(caller);
        let recipient = ExtCore.User.toAID(request.to);
        let token = NEXT_ID;

        LEDGER.put(token, recipient);
        NEXT_ID := NEXT_ID + 1;
    };


    /////////////////
    // Shared NFT //
    ///////////////


    public shared query func nftOfOwner () : async () {};
    public shared query func ownerOfNft () : async () {};


    // NFT things (Departure)
    // There are some really handy things here, maybe we can plug these into EXT in the future.


    ///////////////////
    // Shared Tarot //
    /////////////////


    public shared func randomizedCard () : async Tarot.RandomizedCard {
        let randomness = Random.Finite(await Random.blob());
        let index = do {
            switch (randomness.byte()) {
                case null { throw Error.reject("Randomness failure"); };
                case (?seed) { Int.abs(Float.toInt(Float.fromInt(Nat8.toNat(seed)) / 255.0 * 100.0)); };
            };
        };

        {
            card = TarotData.Cards[index];
            reversed = do {
                switch (randomness.byte()) {
                    case null { throw Error.reject("Randomness failure"); };
                    case (?seed) { Nat8.toNat(seed) > Int.abs(Float.toInt(0.66 * 255.0)); };
                };
            };
        };
    };

    // Get a whole deck with each card in a random position
    // Returns a list of 78 randomized cards, where each card is only represented once
    // public shared query func randomizedDeck () : async Tarot.RandomizedDeck {
    //     // TODO
    // };


    ////////////////////
    // Shared Assets //
    //////////////////


    // TODO: Play with long lived caching (only when in production mode)

    let NOT_FOUND : DlNftHttp.Response = {status_code = 404; headers = []; body = Blob.fromArray([]); streaming_strategy = null};
    let BAD_REQUEST : DlNftHttp.Response = {status_code = 400; headers = []; body = Blob.fromArray([]); streaming_strategy = null};
    let UNAUTHORIZED : DlNftHttp.Response = {status_code = 401; headers = []; body = Blob.fromArray([]); streaming_strategy = null};

    public query func asset (index : Nat) : async ?DlNftTypes.StaticAsset {
        ASSETS[index];
    };

    public query func http_request(request : DlNftHttp.Request) : async DlNftHttp.Response {
        let path = Iter.toArray(Text.tokens(request.url, #text("/")));
        Debug.print("Handle HTTP: " # request.url);

        if (path[0] == "card-art") return _handleCardAssetRequest(path[1]);
        if (path[0] == "card-info") return _handleCardInfoRequest(path[1]);

        return NOT_FOUND;
    };

    private func _handleCardAssetRequest(path : Text) : DlNftHttp.Response {
        var cache = "0";  // No cache
        if (LOCKED) { cache := "86400" };  // Cache one day
        for (i in Iter.range(0, 79)) {
            if (Int.toText(i) == path) {
                switch(ASSETS[i]) {
                    case null return NOT_FOUND;
                    case (?asset) {
                        return {
                            body = asset.payload[0];
                            headers = [
                                ("Content-Type", asset.contentType),
                                ("Cache-Control", "max-age=" # cache),
                            ];
                            status_code = 200;
                            streaming_strategy = null;
                        };
                    };
                };
            };
        };
        return NOT_FOUND;
    };

    private func _handleCardInfoRequest(path : Text) : DlNftHttp.Response {
        for (i in Iter.range(0, 79)) {
            if (Int.toText(i) == path) {
                return {
                    body = TarotData.Cards[i];
                    headers = [
                        ("Cache-Control", "max-age=3154000000"),  // Cache 100 years
                    ];
                    status_code = 200;
                    streaming_strategy = null;
                };
            };
        };
        return NOT_FOUND;
    };


    ///////////////////
    // Shared Admin //
    /////////////////


    type UpdateOwnerRequest = {
        method : { #add; #remove; };
        principal : Principal;
    };

    type UpdateOwnerResponse = Result.Result<[Principal], ExtCore.CommonError>;

    public shared ({ caller }) func updateOwners (request : UpdateOwnerRequest) : async UpdateOwnerResponse {
        assert _isOwner(caller);
        switch (request.method) {
            case (#add) {
                if (_isOwner(request.principal)) {
                    #ok(OWNERS);
                } else {
                    OWNERS := Array.append(OWNERS, [request.principal]);
                    #ok(OWNERS);
                }
            };
            case (#remove) {
                OWNERS := Array.filter<Principal>(OWNERS, func(v) {v != request.principal});
                #ok(OWNERS);
            }
        };
    };

    type AssetAdminRequest = {
        index : Nat;
        asset : DlNftTypes.StaticAsset;
    };

    type AssetAdminResponse = Result.Result<(), ExtCore.CommonError>;

    public shared ({ caller }) func assetAdmin (request : AssetAdminRequest) : async AssetAdminResponse {
        assert _isOwner(caller);
        assert LOCKED == false;
        ASSETS[request.index] := ?request.asset;
        #ok()
    };

    public shared ({ caller }) func assetCheck () : async Result.Result<(), [Nat]> {
        assert _isOwner(caller);
        var missingAssets : [Nat] = [];
        for (i in Iter.range(0, 79)) {
            if (Option.isNull(ASSETS[i])) {
                missingAssets := Array.append(missingAssets, [i]);
            };
        };
        if (Iter.size(Iter.fromArray(missingAssets)) == 0) {
            return #ok();
        } else {
            return #err(missingAssets);
        };
    };

    public shared ({ caller }) func assetLock () : async Bool {
        assert _isOwner(caller);
        LOCKED := not LOCKED;
        LOCKED;
    };


    ////////////////////
    // Shared Cycles //
    //////////////////


    /* It's nice to be able to send, receive and query cycles.
     */
    public shared func c4Query() : async Nat {
        await C4.available();
    };
    public shared func c4Donate() : async Nat {
        Debug.print(Nat.toText(Cycles.available()));
        await C4.accept();
    };
    public shared ({ caller }) func c4Withdraw(amount : Nat) : async Nat {
        assert _isOwner(caller);
        await C4.send(amount);
    };

    /////////////////////////
    // Contract Internals //
    ///////////////////////

    // Access Control

    func _isOwner(principal : Principal) : Bool {
        switch(Array.find<Principal>(OWNERS, func (v) { v == principal })) {
            case (null) return false;
            case (?v) return true;
        };
    };

    private func _addOwner(principal : Principal) {
        if (_isOwner(principal)) {
            return;
        };
        OWNERS := Array.append(OWNERS, [principal]);
    };

    private func _removeOwner(principal : Principal) {
        OWNERS := Array.filter<Principal>(OWNERS, func (v) {v != principal});
    };

};
