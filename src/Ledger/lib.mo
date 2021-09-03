import Array "mo:base/Array";
import Blob "mo:base/Blob";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import ExtCore "mo:ext/Core";
import ExtNonFungible "mo:ext/NonFungible";
import ExtAccountId "mo:ext/util/AccountIdentifier";

import Types "types";

module {

    public class Ledger (state : Types.State) {


        ////////////
        // State //
        //////////

        let ledger = HashMap.HashMap<ExtCore.TokenIndex, ExtCore.AccountIdentifier>(
            state.ledgerEntries.size(),
            ExtCore.TokenIndex.equal,
            ExtCore.TokenIndex.hash,
        );

        // Denormalized ledger indexed on users
        let entriesByUser = HashMap.HashMap<ExtCore.AccountIdentifier, [ExtCore.TokenIndex]>(
            state.ledgerEntries.size(),
            ExtAccountId.equal,
            ExtAccountId.hash,
        );

        let extMetaData : Types.ExtMetadata = #nonfungible({
            metadata = ?[Blob.fromArray([])];
        });

        // Initialize the class with state from the parent actor,
        // state is passed back up during canister upgrade:

        public var nextTokenId = state.nextTokenId;

        for ((tokenIndex, accountIdentifier) in Iter.fromArray(state.ledgerEntries)) {
            ledger.put(tokenIndex, accountIdentifier);
            _indexToken(tokenIndex, accountIdentifier, entriesByUser);
        };


        //////////
        // API //
        ////////

        public func entries () : [(ExtCore.TokenIndex, ExtCore.AccountIdentifier)] {
            Iter.toArray(ledger.entries());
        };

        // Ext standard: get balance
        public func balance (request : ExtCore.BalanceRequest, canisterPrincipal : Principal) : ExtCore.BalanceResponse {
            if (not ExtCore.TokenIdentifier.isPrincipal(request.token, canisterPrincipal)) {
                return #err(#InvalidToken(request.token));
            };
            let token = ExtCore.TokenIdentifier.getIndex(request.token);
            let aid = ExtCore.User.toAID(request.user);
            switch (ledger.get(token)) {
                case (?owner) {
                    if (ExtAccountId.equal(aid, owner)) return #ok(1);
                    return #ok(0);
                };
                case Null #err(#InvalidToken(request.token));
            };
        };

        // Ext standard: transfer owner
        public func transfer (request : ExtCore.TransferRequest, caller : Principal, canisterPrincipal : Principal) : ExtCore.TransferResponse {
            if (request.amount != 1) {
                return #err(#Other("Only logical transfer amount for an NFT is 1, got" # Nat.toText(request.amount) # "."));
            };
            if (not ExtCore.TokenIdentifier.isPrincipal(request.token, canisterPrincipal)) {
                return #err(#InvalidToken(request.token));
            };
            let token = ExtCore.TokenIdentifier.getIndex(request.token);
            let owner = ExtCore.User.toAID(request.from);
            let agent = ExtAccountId.fromPrincipal(caller, request.subaccount);
            let recipient = ExtCore.User.toAID(request.to);
            switch (ledger.get(token)) {
                case (?tokenOwner) {
                    if (ExtAccountId.equal(owner, tokenOwner) and ExtAccountId.equal(owner, agent)) {
                        ledger.put(token, recipient);
                        return #ok(request.amount);
                    };
                    #err(#Unauthorized(owner));
                };
                case Null return #err(#InvalidToken(request.token));
            };
        };

        // Ext standard: get bearer of token
        public func bearer (token : ExtCore.TokenIdentifier, canisterPrincipal : Principal) : Result.Result<ExtCore.AccountIdentifier, ExtCore.CommonError> {
            if (not ExtCore.TokenIdentifier.isPrincipal(token, canisterPrincipal)) {
                return #err(#InvalidToken(token));
            };
            let i = ExtCore.TokenIdentifier.getIndex(token);
            switch (ledger.get(i)) {
                case (?owner) #ok(owner);
                case Null #err(#InvalidToken(token));
            };
        };

        // Ext standard: mint an NFT
        public func mint (request : ExtNonFungible.MintRequest) : () {
            let recipient = ExtCore.User.toAID(request.to);
            let token = nextTokenId;

            ledger.put(token, recipient);
            _indexToken(token, recipient, entriesByUser);
            nextTokenId := nextTokenId + 1;
        };

        // Ext standard: metadata
        public func metadata (token : ExtCore.TokenIdentifier) : Result.Result<Types.ExtMetadata, ExtCore.CommonError> {
            return #ok(extMetaData);
        };

        // Ext standard: Supply
        public func supply(token : ExtCore.TokenIdentifier) : Result.Result<ExtCore.Balance, ExtCore.CommonError> {
            #ok(Iter.size(ledger.entries()));
        };

        public func getUserTokens (user : ExtCore.User) : [ExtCore.TokenIndex] {
            switch (entriesByUser.get(ExtCore.User.toAID(user))) {
                case (null) [];
                case (?entries) entries;
            };
        };

    };

    // Convenience method to add a token to our denormalized index maps
    private func _indexToken (
        token : ExtCore.TokenIndex,
        id : ExtCore.AccountIdentifier,
        map : HashMap.HashMap<ExtCore.AccountIdentifier, [ExtCore.TokenIndex]>
    ) : () {
        switch (map.get(id)) {
            case (null) map.put(id, [token]);
            case (?tokens) map.put(id, Array.append(tokens, [token]));
        };
    };

};