import Result "mo:base/Result";

import ExtCore "mo:ext/Core";


module CanTypes {

    public type State = {
        initialized : Bool;
        metadata : Metadata;
        owners : [Principal];
        locked : Bool;
    };

    public type Metadata = {
        name : Text;
        symbol : Text;
        description : Text;
        artists : [Text];
    };

    public type InitRequest = {
        owners : [Principal];
        metadata : Metadata;
    };

    public type InitResponse = ([Principal], Metadata);

    public type UpdateOwnerRequest = {
        method : { #add; #remove; };
        principal : Principal;
    };

    public type UpdateOwnerResponse = Result.Result<[Principal], ExtCore.CommonError>;

};