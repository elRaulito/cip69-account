use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Inline, VerificationKey}
use cardano/transaction.{OutputReference, Transaction}

const myPubKey = #"1c471b31ea0b04c652bd8f76b239aea5f57139bdc5a2b28ab1e69175"

pub type Datum {
  owner: VerificationKeyHash,
}

pub type Redeemer {
  msg: ByteArray,
}

//voglio che se firmo io posso ritirare altrimenti è un qualcosa con un datum suo

validator cip69 {
  spend(
    datum: Option<Datum>,
    _redeemer: Redeemer,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    when datum is {
      None -> {
        expect Some(input) =
          self.inputs
            |> transaction.find_input(own_ref)

        when input.output.address.stake_credential is {
          None -> list.has(self.extra_signatories, myPubKey)
          Some(stake_cred) ->
            when stake_cred is {
              Inline(a) -> {
                expect VerificationKey(hash) = a
                list.has(self.extra_signatories, hash)
              }
              _ -> False
            }
        }
      }

      Some(_) -> list.has(self.extra_signatories, myPubKey)
    }
  }

  else(_) {
    fail
  }
}
