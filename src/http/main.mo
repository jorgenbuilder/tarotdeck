import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import DlHttp "mo:dl-nft/http";


module Http {

    public query func http_request(request : DlHttp.Request) : async DlHttp.Response {
        Debug.print("Handle HTTP: " # request.url);
        
        if (Text.contains(request.url, #text("?tokenid"))) {
            // EXT preview
            return httpCardAsset("0");
        };

        let path = Iter.toArray(Text.tokens(request.url, #text("/")));

        if (path[0] == "card-art") return httpCardAsset(path[1]);
        if (path[0] == "card-info") return httpCardInfo(path[1]);

        return NOT_FOUND;
    };

    private func httpCardAsset(path : Text) : DlHttp.Response {
        var cache = "0";  // No cache
        if (LOCKED) { cache := "86400" };  // Cache one day

        for (i in Iter.range(0, 79)) {
            if (Int.toText(i) == path) {
                switch(ASSETS[i]) {
                    case null return NOT_FOUND;
                    case (?asset) {
                        return {
                            body = asset.payload[0];
                            headers = [
                                ("Content-Type", asset.contentType),
                                ("Cache-Control", "max-age=" # cache),
                            ];
                            status_code = 200;
                        };
                    };
                };
            };
        };
        return NOT_FOUND;
    };

    private func httpCardInfo(path : Text) : DlHttp.Response {
        var cache = "0";  // No cache
        if (LOCKED) { cache := "3154000000" };  // Cache 100 years

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
                };
            };
        };
        return NOT_FOUND;
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