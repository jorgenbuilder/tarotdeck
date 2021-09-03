import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

import DlHttp "mo:dl-nft/http";

import Tarot "../Tarot/types";
import TarotData "../Tarot/data";

import Types "types";


module {

    public class HttpHandler (state : Types.State) {

        public func request(request : DlHttp.Request) : DlHttp.Response {
            Debug.print("Handle HTTP: " # request.url);
            
            if (Text.contains(request.url, #text("tokenid"))) {
                // EXT preview
                return httpCardAsset("0");
            };

            let path = Iter.toArray(Text.tokens(request.url, #text("/")));

            if (path[0] == "card-art") return httpCardAsset(path[1]);
            if (path[0] == "card-info") return httpCardInfo(path[1]);

            return DlHttp.NOT_FOUND();
        };

        private func httpCardAsset(path : Text) : DlHttp.Response {
            var cache = "0";  // No cache
            if (state.locked) { cache := "86400" };  // Cache one day

            for (i in Iter.range(0, 79)) {
                if (Int.toText(i) == path) {
                    switch(state.getCardArt(i)) {
                        case (null) return DlHttp.NOT_FOUND();
                        case (?asset) {
                            return {
                                body = asset.payload[0];
                                headers = [
                                    ("Content-Type", asset.contentType),
                                    ("Cache-Control", "max-age=" # cache),
                                ];
                                status_code = 200;
                                streaming_strategy = null;
                            };
                        };
                    };
                };
            };
            return DlHttp.NOT_FOUND();
        };

        private func httpCardInfo(path : Text) : DlHttp.Response {
            var cache = "0";  // No cache
            if (state.locked) { cache := "3154000000" };  // Cache 100 years

            for (i in Iter.range(0, 79)) {
                if (Int.toText(i) == path) {
                    let resp : Text = serializeCard(TarotData.Cards[i]);
                    Debug.print(resp);

                    return {
                        body = Text.encodeUtf8(resp);
                        headers = [
                            ("Content-Type", "text/json"),
                            ("Cache-Control", "max-age=" # cache),  
                        ];
                        status_code = 200;
                        streaming_strategy = null;
                    };
                };
            };
            return DlHttp.NOT_FOUND();
        };

        private func serializeCard (card : Tarot.Card) : Text {
            "{" #
                "\"name\": \"" # card.name # "\", " #
                "\"number\": \"" # Nat.toText(card.number) # "\", " #
                "\"suit\": \"" # (switch (card.suit) {
                    case (#trump) "trump";
                    case (#wands) "wands";
                    case (#pentacles) "pentacles";
                    case (#cups) "cups";
                    case (#swords) "swords";
                }) # "\", " #
                "\"index\": \"" # Nat.toText(card.index) # "\"" #
            "}"
        };

    };
};