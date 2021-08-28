import LedgerTypes "./type";


module {

    public class Ledger (
        nextId : Nat;
        entries : 
    )

    ////////////
    // State //
    //////////

    // I found that this was necessary to interoperate with Stoic
    private stable let extMetaData : LedgerTypes.ExtMetadata = #nonfungible({
        metadata = ?[Blob.fromArray([])];
    }); 


    //////////
    // API //
    ////////

    // Ext standard: balance
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

    // Ext standard: get bearer of token
    // TODO: Am I using this anywhere?
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

    // Ext standard: metadata
    public shared query func metadata (token : ExtCore.TokenIdentifier) : async Result.Result<Metadata, ExtCore.CommonError> {
        return #ok(EXTMETADATA);
    };

    // Ext standard: mint an NFT
    public shared ({ caller }) func mint (request : ExtNonFungible.MintRequest) : async () {
        assert _isOwner(caller);
        let recipient = ExtCore.User.toAID(request.to);
        let token = NEXT_ID;

        LEDGER.put(token, recipient);
        NEXT_ID := NEXT_ID + 1;
    };

    // Ext standard: Supply
    public query func supply(token : ExtCore.TokenIdentifier) : async Result.Result<ExtCore.Balance, ExtCore.CommonError> {
        #ok(Iter.size(LEDGER.entries()));
    };


    ///////////////
    // Internal //
    /////////////

};