module Types {

    type UpdateOwnerRequest = {
        method : { #add; #remove; };
        principal : Principal;
    };

    type UpdateOwnerResponse = Result.Result<[Principal], ExtCore.CommonError>;

};