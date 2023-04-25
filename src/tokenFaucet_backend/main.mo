import myToken "canister:icrc1-ledger";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Time "mo:base/Time";
import Iter "mo:base/Iter";

actor backend {

  private type Result<T, E> = Result.Result<T, E>;

  private var hasClaimed = HashMap.HashMap<Principal, Bool>(
    1,
    Principal.equal,
    Principal.hash,
  );

  private var lastClaim = HashMap.HashMap<Principal, Int>(
    1,
    Principal.equal,
    Principal.hash,
  );

  private stable var hasClaimedArray : [(Principal, Bool)] = [];
  private stable var lastClaimArray : [(Principal, Int)] = [];

  let waitingTime : Nat = 24 * 60 * 60 * 1000000000;

  var tokenAmount : Nat = 0;

  public func claimTokens(account : Principal) : async Result<Text, Text> {

    if (not Principal.isAnonymous(account)) {

      let claim = switch (hasClaimed.get(account)) {
        case null false;
        case (?v) v;
      };

      if (claim) {

        tokenAmount := 5000;

        let lastTokenClaim : Int = switch (lastClaim.get(account)) {
          case null 0;
          case (?value) value;
        };

        if (not (lastTokenClaim == 0)) {

          if ((lastTokenClaim + waitingTime) < Time.now()) {

            let transferResult = await transferTokens(tokenAmount, account);
            if (transferResult == #ok("success")) {
              lastClaim.put(account, (Time.now()));
              #ok("You have successfully claimed more 5000 tokens");

            } else {

              #err("Error in claiming tokens 1. Try again later");

            }

          } else {

            #err("You need to wait for 24 hours before you can request more tokens.");

          }

        } else {
          #err("Error in determing eligibility");
        }

      } else {

        tokenAmount := 15000;

        let transferResult = await transferTokens(tokenAmount, account);
        if (transferResult == #ok("success")) {

          hasClaimed.put(account, true);
          lastClaim.put(account, (Time.now()));
          #ok("You have successfully claimed 15000 tokens for the first time.");

        } else {

          #err("Error in claiming tokens 2. Try again later");

        }

      };
    } else {
      #err("Use a valid Principal ID to claim tokens");
    }

  };

  private func transferTokens(tokens : Nat, account : Principal) : async Result<Text, Text> {

    let result = await myToken.icrc1_transfer({

      amount = tokens;
      from_subaccount = null;
      created_at_time = null;
      fee = null;
      memo = null;
      to = {
        owner = account;
        subaccount = null;
      };

    });

    switch (result) {

      case (#Err(transferError)) {
        #err("failure");
      };
      case (_) {
        #ok("success");
      };

    };

  };

  system func preupgrade() {
    hasClaimedArray := Iter.toArray(hasClaimed.entries());
    lastClaimArray := Iter.toArray(lastClaim.entries());
  };

  system func postupgrade() {
    hasClaimed := HashMap.fromIter<Principal, Bool>(
      hasClaimedArray.vals(),
      1,
      Principal.equal,
      Principal.hash,
    );
    lastClaim := HashMap.fromIter<Principal, Int>(
      lastClaimArray.vals(),
      1,
      Principal.equal,
      Principal.hash,
    );
  };

};