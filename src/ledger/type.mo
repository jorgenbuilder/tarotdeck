import HashMap "mo:base/Hashmap";

import ExtCore "mo:ext/Core";

module LedgerTypes {

    public type State = {
        
    };

    public type Ledger = HashMap.HashMap<ExtCore.TokenIndex, ExtCore.AccountIdentifier>;

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