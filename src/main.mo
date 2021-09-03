import Array "mo:base/Array";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Random "mo:base/Random";
import Result "mo:base/Result";
import Text "mo:base/Text";

import DlStatic "mo:dl-nft/static";
import DlHttp "mo:dl-nft/http";
import ExtCore "mo:ext/Core";
import ExtNonFungible "mo:ext/NonFungible";

import Assets "Assets";
import AssetTypes "Assets/types";
import Http "Http";
import Ledger "Ledger";
import LedgerTypes "Ledger/types";
import Tarot "Tarot";
import TarotTypes "Tarot/types";


shared ({ caller = creator }) actor class BetaDeck() = canister {


    ////////////
    // State //
    //////////


    // Admin and metadata

    stable var initialized : Bool = false;
    stable var deckmeta : TarotTypes.Metadata = {
        name = "Uninitialized";
        flavour = "";
        description = "";
        artists = [];
    };
    stable var owners : [Principal] = [creator];
    stable var locked : Bool = false;

    // Ledger

    stable var nextTokenId : ExtCore.TokenIndex = 0;
    stable var ledgerEntries : [(ExtCore.TokenIndex, ExtCore.AccountIdentifier)] = [];
    let ledger = Ledger.Ledger({ nextTokenId; ledgerEntries; });

    // Art assets

    stable let assetEntries : [var ?DlStatic.Asset] = Array.init<?DlStatic.Asset>(80, null);
    stable let PREVIEW_ASSET : ?DlStatic.Asset = null;  // Doesn't do anything yet

    // Upgrades

    system func preupgrade() {
        nextTokenId := ledger.nextTokenId;
        ledgerEntries := ledger.entries();
        locked := assets.locked;
        deckmeta := tarot.getDeckInfo();
    };

    system func postupgrade() {
        ledgerEntries := [];
    };


    //////////
    // API //
    ////////


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
                    #ok(owners);
                } else {
                    owners := Array.append(owners, [request.principal]);
                    #ok(owners);
                }
            };
            case (#remove) {
                owners := Array.filter<Principal>(owners, func(v) {v != request.principal});
                #ok(owners);
            }
        };
    };

    // A canister must be initialized with its owners and initial data before it can be used.
    public shared ({caller}) func init (initOwners : [Principal], metadata : TarotTypes.Metadata) : async ([Principal], TarotTypes.Metadata) {
        assert not initialized and caller == owners[0];
        let meta = tarot.setDeckInfo(metadata);
        owners := Array.append(owners, initOwners);
        initialized := true;
        (owners, meta);
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

    public query func getUserTokens(user : ExtCore.User) : async [ExtCore.TokenIndex] {
        ledger.getUserTokens(user);
    };


    // Tarot deck

    let tarot = Tarot.Tarot({ deckmeta; });

    public shared func getRandomizedCard () : async { #ok : TarotTypes.RandomizedCard; #error : Text; } {
        await tarot.getRandomizedCard();
    };

    public query func getCardInfo (index : Nat) : async ?TarotTypes.Card {
        tarot.getCardInfo(index);
    };

    public query func getDeckInfo () : async TarotTypes.Metadata {
        tarot.getDeckInfo();
    };

    public shared ({ caller }) func setDeckInfo (metadata : TarotTypes.Metadata) : async TarotTypes.Metadata {
        assert(_isOwner(caller));
        tarot.setDeckInfo(metadata);
    };


    // Assets

    let assets = Assets.Assets({ assetEntries; locked; });

    public query func getCardArt (index : Nat) : async ?DlStatic.Asset {
        assets.getCardArt(index);
    };

    public shared ({ caller }) func assetAdmin (request : AssetTypes.AssetAdminRequest) : async AssetTypes.AssetAdminResponse {
        assert _isOwner(caller);
        assets.assetAdmin(request);
    };

    public shared ({ caller }) func assetCheck () : async Result.Result<(), [Nat]> {
        assert _isOwner(caller);
        assets.assetCheck();
    };

    public shared ({ caller }) func assetLock () : async Bool {
        assert _isOwner(caller);
        assets.assetLock();
    };


    // HTTP

    let httpHandler = Http.HttpHandler({ locked; getCardArt = assets.getCardArt; });

    public query func http_request(request : DlHttp.Request) : async DlHttp.Response {
        httpHandler.request(request);
    };


    // Cycles

    public query func wallet_balance () : async Nat {
        Cycles.balance();
    };

    public func wallet_receive () : async Nat {
        Cycles.accept(Cycles.available());
    };
    

    ////////////////
    // Internals //
    //////////////
    

    func _isOwner(principal : Principal) : Bool {
        switch(Array.find<Principal>(owners, func (v) { v == principal })) {
            case (null) return false;
            case (?v) return true;
        };
    };

    private func _addOwner(principal : Principal) {
        if (_isOwner(principal)) {
            return;
        };
        owners := Array.append(owners, [principal]);
    };

    private func _removeOwner(principal : Principal) {
        owners := Array.filter<Principal>(owners, func (v) {v != principal});
    };

};
