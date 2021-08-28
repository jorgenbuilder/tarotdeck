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
import Result "mo:base/Result";
import Option "mo:base/Option";
import Text "mo:base/Text";

import DlNft "mo:dl-nft/main";
import DlNftTypes "mo:dl-nft/types";
import DlStatic "mo:dl-nft/static";

import ExtCore "mo:ext/Core";
import ExtCommon "mo:ext/Common";
import ExtNonFungible "mo:ext/NonFungible";
import ExtAccountId "mo:ext/util/AccountIdentifier";

import Can "./can";

import Tarot "./tarot";
import TarotTypes "./tarot/type";

import Ledger "./ledger";

import Types "./types";


////////////////////////////
// BETADECK CONTRACT 📜 //
/////////////////////////


shared ({ caller = creator }) actor class BetaDeck() = canister {


    ////////////
    // State //
    //////////

    // Canister metadata and administration
    let can = Can.Can();

    // Ledger
    stable var ledgerItems : [(ExtCore.TokenIndex, ExtCore.AccountIdentifier)] = [];
    let ledger = Ledger.Ledger(ledgerItems);

    // Deck assets
    stable let assets : [var ?DlStatic.Asset] = Array.init<?DlStatic.Asset>(80, null);

    // Tarot deck properties
    let tarotDeck = Tarot.

    // Upgrades
    system func preupgrade() {
        ledgerItems := Iter.toArray(LEDGER.entries());
    };

    system func postupgrade() {
        ledgerItems := [];
    };


    //////////
    // API //
    ////////


    // A canister must be initialized with its owners and initial data before it can be used.
    public shared ({caller}) func init (owners : [Principal], metadata : TarotTypes.DeckCanMeta) : async ([Principal], TarotTypes.DeckCanMeta) {
        
    }
    


    /////////////
    // Ledger //
    ///////////


    public shared ({caller}) func balance (request : ExtNonFungible.BalanceRequest) : async ExtCore.BalanceResponse {
        await ledger.balance(request);
    };
    
    public shared ({caller}) func bearer ((token : ExtCore.TokenIdentifier) : async Result.Result<ExtCore.AccountIdentifier, ExtCore.CommonError> {
        await ledger.bearer(token);
    };

    public shared ({caller}) func metadata (token : ExtCore.TokenIdentifier) : async Result.Result<Metadata, ExtCore.CommonError> {
        await ledger.metadata(token);
    };

    public shared ({caller}) func mint (request : ExtNonFungible.MintRequest) : async () {
        await ledger.mint(request);
    };
    
    public shared ({caller}) func supply (token : ExtCore.TokenIdentifier) : async Result.Result<ExtCore.Balance, ExtCore.CommonError> {
        await ledger.supply(token);
    };

    public shared ({caller}) func transfer (request : ExtNonFungible.TransferRequest) : async ExtCore.TransferResponse {
        await ledger.transfer(request);
    };


    /////////////////
    // Tarot Deck //
    ///////////////


    public shared query func getDeckMetaData () : async TarotTypes.DeckCanMeta {
        METADATA;
    };


    ////////////////
    // Can Admin //
    //////////////

    public shared ({ caller }) func updateOwners (request : Types.UpdateOwnerRequest) : async Types.UpdateOwnerResponse {
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

    private func _isOwner(principal : Principal) : Bool {
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
