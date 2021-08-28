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
import DlStatic "mo:dl-nft/static";
import DlNftTypes "mo:dl-nft/types";
import DlHttp "mo:dl-nft/http";
import ExtCore "mo:ext/Core";
import ExtCommon "mo:ext/Common";
import ExtNonFungible "mo:ext/NonFungible";
import ExtAccountId "mo:ext/util/AccountIdentifier";

import Http "./Http";
import Ledger "./Ledger";
import LedgerTypes "./Ledger/types";
import Tarot "./types/tarot";
import TarotData "./data/tarot";


shared ({ caller = creator }) actor class BetaDeck() = canister {


    ////////////
    // State //
    //////////

    // Admin and metadata

    stable var INITIALIZED : Bool = false;
    stable var METADATA : Tarot.DeckCanMeta = {
        name = "Uninitialized";
        symbol = "🥚";
        description = "";
        artists = [];
    };
    stable var OWNERS : [Principal] = [creator];
    stable var LOCKED : Bool = false;

    // Ledger

    stable var nextTokenId : ExtCore.TokenIndex = 0;
    stable var ledgerEntries : [(ExtCore.TokenIndex, ExtCore.AccountIdentifier)] = [];
    let ledger = Ledger.Ledger({ nextTokenId; ledgerEntries; });

    // Art assets

    stable let ASSETS : [var ?DlStatic.Asset] = Array.init<?DlStatic.Asset>(80, null);

    stable let PREVIEW_ASSET : ?DlStatic.Asset = null;

    // Upgrades

    system func preupgrade() {
        nextTokenId := ledger.nextTokenId;
        ledgerEntries := ledger.entries();
    };

    system func postupgrade() {
        ledgerEntries := [];
    };


    //////////
    // API //
    ////////


    // A canister must be initialized with its owners and initial data before it can be used.
    public shared ({caller}) func init (owners : [Principal], metadata : Tarot.DeckCanMeta) : async ([Principal], Tarot.DeckCanMeta) {
        assert not INITIALIZED and caller == OWNERS[0];
        OWNERS := Array.append(OWNERS, owners);
        METADATA := metadata;
        INITIALIZED := true;
        (OWNERS, METADATA);
    };

    // Return basic information describing this canister and the deck that it represents.
    public shared query func deckmetadata () : async Tarot.DeckCanMeta {
        METADATA;
    };


    // Ledger


    public query func balance (request : ExtCore.BalanceRequest) : async ExtCore.BalanceResponse {
        ledger.balance(request, Principal.fromActor(canister));
    };

    public shared ({ caller }) func transfer (request : ExtCore.TransferRequest) : async ExtCore.TransferResponse {
        ledger.transfer(request, caller, Principal.fromActor(canister));
    };

    public query func bearer (token : ExtCore.TokenIdentifier) : async Result.Result<ExtCore.AccountIdentifier, ExtCore.CommonError> {
        ledger.bearer(token, Principal.fromActor(canister));
    };

    public shared ({ caller }) func mint (request : ExtNonFungible.MintRequest) : async () {
        assert _isOwner(caller);
        ledger.mint(request);
    };

    public query func metadata (token : ExtCore.TokenIdentifier) : async Result.Result<LedgerTypes.ExtMetadata, ExtCore.CommonError> {
        ledger.metadata(token);
    };

    public query func supply(token : ExtCore.TokenIdentifier) : async Result.Result<ExtCore.Balance, ExtCore.CommonError> {
        ledger.supply(token);
    };

    public shared ({ caller }) func readLedger () : async [(ExtCore.TokenIndex, ExtCore.AccountIdentifier)] {
        assert _isOwner(caller);
        ledger.entries();
    };


    // Tarot deck


    public shared func randomzedCard () : async { #ok : Tarot.RandomizedCard; #error : Text; } {
        let randomness = Random.Finite(await Random.blob());
        _randomizedCard(randomness)
    };
    

    private func _randomizedCard (randomness : Random.Finite) : { #ok : Tarot.RandomizedCard; #error : Text; } {
        let index = do {
            switch (randomness.byte()) {
                case null { return #error("Randomness failure") };
                case (?seed) { Int.abs(Float.toInt(Float.fromInt(Nat8.toNat(seed)) / 255.0 * 100.0)); };
            };
        };

        return #ok({
            card = TarotData.Cards[index];
            reversed = do {
                switch (randomness.byte()) {
                    case null { return #error("Randomness failure") };
                    case (?seed) { Nat8.toNat(seed) > Int.abs(Float.toInt(0.66 * 255.0)); };
                };
            };
        });
    };

    // Get a whole deck with each card in a random position
    // Returns a list of 78 randomized cards, where each card is only represented once
    // public shared query func randomizedDeck () : async Tarot.RandomizedDeck {
    //     // TODO
    // };


    // Assets


    public query func asset (index : Nat) : async ?DlStatic.Asset {
        ASSETS[index];
    };

    public query func cardInfo (index : Nat) : async ?Tarot.Card {
        ?TarotData.Cards[index];
    };


    // HTTP


    let httpHandler = Http.HttpHandler({ locked = LOCKED; assets = Array.freeze(ASSETS); });

    public query func http_request(request : DlHttp.Request) : async DlHttp.Response {
        httpHandler.request(request);
    };


    // Admin


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
        asset : DlStatic.Asset;
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
    

    ////////////////
    // Internals //
    //////////////
    

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
