import Nat "mo:base/Nat";
import Text "mo:base/Text";


module TarotTypes {

    public type DeckCanConfig = {
        allowAnonymousDraws : Bool;
    };

    public type Suit = { #trump; #wands; #pentacles; #swords; #cups; };

    public type Card = {
        index : Nat;
        name : Text;
        number : Nat;
        suit : Suit;
    };

    public type RandomizedCard = {
        card : Card;
        reversed : Bool;
    };

    public type RandomizedDeck = [RandomizedCard];

};