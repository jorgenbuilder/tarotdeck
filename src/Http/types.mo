import DlStatic "mo:dl-nft/static";

module {

    public type State = {
        getCardArt : (index : Nat) -> ?DlStatic.Asset;
        locked : Bool;
    };

};