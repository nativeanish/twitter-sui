/// Microfinance module for managing savings accounts, loans, and lending pools.
module microfinance::microfinance {
    // Import necessary modules and types from the SUI framework and standard library.
    use sui::object::{Self, UID};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::sui::SUI;
    use std::vector;
    use sui::tx_context::{Self, TxContext, sender};

    use microfinance::usdt::{Self, CapWrapper, USDT};

    // === Errors ===

    const ENotEnoughBalance: u64 = 0;
    const EBorrowAmountIsTooHigh: u64 = 1;
    const EAccountMustBeEmpty: u64 = 2;
    const EPayYourLoan: u64 = 3;
    const ENotOwner: u64 = 4;

    // === Constants ===

    const EXCHANGE_RATE: u128 = 40;

    // Define structs for various entities in the microfinance system.

    /// Represents a borrower's account, including their balance and active loans.
    struct Account has key, store {
        id: UID, // Unique identifier for the account.
        owner: address, // Address of the account owner.
        debt: u64, // Current balance of the account.
        balance: u64,
    }

    /// Represents the lending pool, including total funds and outstanding loans.
    struct LendingPool has key, store {
        id: UID, // Unique identifier for the lending pool.
        balance: Balance<SUI>, // Total funds available in the lending pool.
        loans_outstanding: vector<UID>, // IDs of outstanding loans.
    }

    // Functions for creating and managing accounts and loans.

    /// Creates a new borrower account with an initial balance of zero.
    public fun new_account(ctx: &mut TxContext) {
        let account = Account {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            debt: 0,
            balance: 0,
        };
        transfer::public_transfer(account, sender(ctx));
    }

    /// Initializes a new lending pool with a specified initial amount.
    public fun new_pool(ctx: &mut TxContext) {
        let pool = LendingPool {
            id: object::new(ctx),
            balance: balance::zero(),
            loans_outstanding: vector::empty(),
        };
        transfer::share_object(pool);
    }

    /// Deposits funds into the lending pool from a lender's account.
    public fun deposit(account: &mut Account, pool: &mut LendingPool, amount: Coin<SUI>) {
        let deposit_balance = coin::into_balance<SUI>(amount);
        let amount = balance::value(&deposit_balance);
        // add sui to pool
        balance::join(&mut pool.balance, deposit_balance); 
        // increase the user balance 
        account.balance = account.balance + amount;
    }

    // withdraw sui coin from the pool
    public fun withdraw(self: &mut LendingPool, account: &mut Account, value: u64, ctx: &mut TxContext): Coin<SUI> {
        assert!(sender(ctx) == account.owner, ENotOwner);
        assert!(account.debt == 0, EPayYourLoan);
        assert!(account.balance >= value, ENotEnoughBalance);

        account.balance = account.balance - value;

        coin::from_balance(balance::split(&mut self.balance, value), ctx)
    } 
    // borrow stabil coin from pool
    public fun borrow(account: &mut Account, cap: &mut CapWrapper, value: u64, ctx: &mut TxContext): Coin<USDT> {
        assert!(sender(ctx) == account.owner, ENotOwner);
        let max_borrow_amount = (((account.balance as u128) * EXCHANGE_RATE / 100) as u64);

        assert!(max_borrow_amount >= account.debt + value, EBorrowAmountIsTooHigh);

        account.debt = account.debt + value;
        usdt::mint(cap, value, ctx)
    }
    // pay your debt to withdraw SUI
    public fun repay(account: &mut Account, cap: &mut CapWrapper, coin_in: Coin<USDT>) {

        let amount = usdt::burn(cap, coin_in);

        account.debt = account.debt - amount;
    } 
    // destroy your account 
    public fun destroy_empty_account(account: Account, ctx: &mut TxContext) {
        assert!(sender(ctx) == account.owner, ENotOwner);
        let Account { id, owner: _,debt ,  balance: _} = account;
        assert!(debt == 0, EAccountMustBeEmpty);
        object::delete(id);
    }
 
}
