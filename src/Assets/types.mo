import Result "mo:base/Result";

import DlStatic "mo:dl-nft/static";

import ExtCore "mo:ext/Core";


module {

    public type State = {
        locked : Bool;
        assetEntries : [var ?DlStatic.Asset];
    };

    public type AssetAdminRequest = {
        index : Nat;
        asset : DlStatic.Asset;
    };

    public type AssetAdminResponse = Result.Result<(), ExtCore.CommonError>;

};