import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Result "mo:base/Result";

import DlStatic "mo:dl-nft/static";

import Types "types";


module {
    
    public class Assets (state : Types.State) {


        ////////////
        // State //
        //////////


        public var locked = state.locked;
        var assets = state.assetEntries;


        //////////
        // API //
        ////////


        public func getCardArt (index : Nat) : ?DlStatic.Asset {
            assets[index];
        };


        public func assetAdmin (request : Types.AssetAdminRequest) : Types.AssetAdminResponse {
            assert locked == false;
            assets[request.index] := ?request.asset;
            #ok()
        };

        public func assetCheck () : Result.Result<(), [Nat]> {
            var missingAssets : [Nat] = [];
            for (i in Iter.range(0, 79)) {
                if (Option.isNull(assets[i])) {
                    missingAssets := Array.append(missingAssets, [i]);
                };
            };
            if (Iter.size(Iter.fromArray(missingAssets)) == 0) {
                return #ok();
            } else {
                return #err(missingAssets);
            };
        };

        public func assetLock () : Bool {
            locked := not locked;
            locked;
        };


        ////////////////
        // Internals //
        //////////////

    };

};