module {

    public class Can () {
      
      
        ////////////
        // State //
        //////////

      
        stable var INITIALIZED : Bool = false;
        stable var METADATA : TarotTypes.DeckCanMeta = {
            name = "Uninitialized";
            symbol = "🥚";
            description = "";
            artists = [];
        };
        stable var OWNERS : [Principal] = [creator];
        stable var LOCKED : Bool = false;


        //////////
        // API //
        ////////


        public shared ({caller}) func init (owners : [Principal], metadata : TarotTypes.DeckCanMeta) : async ([Principal], TarotTypes.DeckCanMeta) {
            assert not INITIALIZED and caller == OWNERS[0];
            OWNERS := Array.append(OWNERS, owners);
            METADATA := metadata;
            INITIALIZED := true;
            (OWNERS, METADATA);
        };


        ////////////////
        // Internals //
        //////////////

    };

}