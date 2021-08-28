module LedgerTypes {

    public type Ledger = HashMap.HashMap<ExtCore.TokenIndex, ExtCore.AccountIdentifier> = HashMap.fromIter(ledgerItems.vals(), 0, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);

    public type ExtMetadata = {
        #fungible : {
            name : Text;
            symbol : Text;
            decimals : Nat8;
            metadata : ?[Blob];
        };
        #nonfungible : {
            metadata : ?[Blob];
        };
    };

};