import ExtCore "mo:ext/Core";


module {
    
    public type State = {
        nextTokenId : ExtCore.TokenIndex;
        ledgerEntries : [(ExtCore.TokenIndex, ExtCore.AccountIdentifier)];
    };

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