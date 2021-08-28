import Array "mo:base/Array";

import Types "./type";

module {

    public class Canister (state : Types.State) {
      
      
        ////////////
        // State //
        //////////

        public var initialized = state.initialized;
        public var owners = state.owners;
        public var metadata = state.metadata;
        public var locked = state.locked;


        //////////
        // API //
        ////////


        // A canister must be initialized with its owners and initial data before it can be used.
        public shared func init (request : Types.InitRequest, caller : Principal) : async Types.InitResponse {
            assert not initialized and caller == owners[0];
            owners := Array.append(owners, request.owners);
            metadata := request.metadata;
            initialized := true;
            (owners, metadata);
        };


        ////////////////
        // Internals //
        //////////////

    };

}