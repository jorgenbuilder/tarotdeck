import Float "mo:base/Float";
import Int "mo:base/Int";
import Nat8 "mo:base/Nat8";
import Random "mo:base/Random";

import Data "data";
import Types "types";


module {

    public class Tarot (state : Types.State) {

        var deckmeta = state.deckmeta;

        public func getDeckInfo () : Types.Metadata {
            deckmeta;
        };

        public func setDeckInfo (request : Types.Metadata) : Types.Metadata {
            deckmeta := request;
            deckmeta;
        };

        public func getCardInfo (index : Nat) : ?Types.Card {
            ?Data.Cards[index];
        };

        public func getRandomizedCard () : async { #ok : Types.RandomizedCard; #error : Text; } {
            let randomness = Random.Finite(await Random.blob());
            let index = do {
                switch (randomness.byte()) {
                    case null { return #error("Randomness failure") };
                    case (?seed) { Int.abs(Float.toInt(Float.fromInt(Nat8.toNat(seed)) / 255.0 * 100.0)); };
                };
            };

            return #ok({
                card = Data.Cards[index];
                reversed = do {
                    switch (randomness.byte()) {
                        case null { return #error("Randomness failure") };
                        case (?seed) { Nat8.toNat(seed) > Int.abs(Float.toInt(0.66 * 255.0)); };
                    };
                };
            });
        };
        
    };

};