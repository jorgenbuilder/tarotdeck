import Blob "mo:base/Blob";
import Nat16 "mo:base/Nat16";

import DlNftHttp "mo:dl-nft/httpTypes";

module {
    public type Response = {
        body: Blob;
        headers: [DlNftHttp.HeaderField];
        status_code: Nat16;
    };
}