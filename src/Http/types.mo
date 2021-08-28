import DlStatic "mo:dl-nft/Static";

module {

    public type State = {
        assets : [?DlStatic.Asset];
        locked : Bool;
    };

};