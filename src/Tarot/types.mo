module {

    public type State = {
        deckmeta : Metadata;
    };

    public type Metadata = {
        name : Text;
        flavour : Text;
        description : Text;
        artists : [Text];
    };

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