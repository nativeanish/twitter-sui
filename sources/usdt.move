module microfinance::usdt {
  // === Imports ===

  use std::option;

  use sui::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::coin::{Self, Coin, TreasuryCap};

  // === Friends ===

  friend microfinance::microfinance;


  // === Structs ===  

  struct USDT has drop {}

  struct CapWrapper has key {
    id: UID,
    cap: TreasuryCap<USDT>
  }

  // === Init ===  

  #[lint_allow(share_owned)]
  fun init(witness: USDT, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<USDT>(
            witness, 
            9, 
            b"USDT",
            b"USDT Dollar", 
            b"Stable coin", 
            option::none(), 
            ctx
        );

      transfer::share_object(CapWrapper { id: object::new(ctx), cap: treasury_cap });
      transfer::public_share_object(metadata);
  }

  // === Public-Mutative Functions ===  

  public fun burn(cap: &mut CapWrapper, coin_in: Coin<USDT>): u64 {
    coin::burn(&mut cap.cap, coin_in)
  }

  // === Public-Friend Functions ===  

  public(friend) fun mint(cap: &mut CapWrapper, value: u64, ctx: &mut TxContext): Coin<USDT> {
    coin::mint(&mut cap.cap, value, ctx)
  }

  // === Test Functions ===  

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(USDT {}, ctx);
  }
}