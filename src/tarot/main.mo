import Int "mo:base/Int";
import Float "mo:base/Float";
import Nat8 "mo:base/Nat8";
import Random "mo:base/Random";

import Data "./data";
import Types "./type";


module {

    

    public query func cardInfo (index : Nat) : async ?Types.Card {
        ?Data.Cards[index];
    };

    public shared func randomizedCard () : async { #ok : Types.RandomizedCard; #error : Text; } {
        let randomness = Random.Finite(await Random.blob());
        _randomizedCard(randomness)
    }; 

    private func _randomizedCard (randomness : Random.Finite) : { #ok : Types.RandomizedCard; #error : Text; } {
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

    // Get a whole deck with each card in a random position
    // Returns a list of 78 randomized cards, where each card is only represented once
    // public shared query func randomizedDeck () : async Types.RandomizedDeck {
    //     // TODO
    // };
};