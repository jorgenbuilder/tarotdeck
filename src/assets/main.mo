import Nat "mo:base/Nat";

module Assets {

    public query func asset (index : Nat) : async ?DlStatic.Asset {
        ASSETS[index];
    };

    

};