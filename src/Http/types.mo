import DlStatic "mo:dl-nft/static";

module {

    public type State = {
        assets : [?DlStatic.Asset];
        locked : Bool;
    };

};