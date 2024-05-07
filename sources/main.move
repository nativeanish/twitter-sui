#[allow(unused_use)]
module car_booking::car_booking {

    // Imports
    use sui::transfer;
    use sui::sui::SUI;
    use std::string::{Self, String};
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};

    // Errors
    const EInsufficientFunds: u64 = 1;
    const EInvalidCoin: u64 = 2;
    const ENotCustomer: u64 = 3;
    const EInvalidCar: u64 = 4;
    const ENotCompany: u64 = 5;
    const EInvalidCarBooking: u64 = 6;

    // CarBooking Company 

    struct CarCompany has key {
        id: UID,
        name: String,
        car_prices: Table<ID, u64>, // car_id -> price
        balance: Balance<SUI>,
        memos: Table<ID, CarMemo>, // car_id -> memo
        company: address
    }

    // Customer

    struct Customer has key {
        id: UID,
        name: String,
        customer: address,
        company_id: ID,
        balance: Balance<SUI>,
    }

    // CarMemo

    struct CarMemo has key, store {
        id: UID,
        car_id: ID,
        rental_fee: u64,
        company: address 
    }

    // Car

    struct Car has key {
        id: UID,
        name: String,
        car_type : String,
        company: address,
        available: bool,
    }

    // Record of Car Booking

    struct BookingRecord has key, store {
        id: UID,
        customer_id: ID,
        car_id: ID,
        customer: address,
        company: address,
        paid_fee: u64,
        rental_fee: u64,
        booking_time: u64
    }

    // Create a new CarCompany object 

    public fun create_company(ctx:&mut TxContext, name: String) {
        let company = CarCompany {
            id: object::new(ctx),
            name: name,
            car_prices: table::new<ID, u64>(ctx),
            balance: balance::zero<SUI>(),
            memos: table::new<ID, CarMemo>(ctx),
            company: tx_context::sender(ctx)
        };

        transfer::share_object(company);
    }

    // Create a new Customer object

    public fun create_customer(ctx:&mut TxContext, name: String, company_address: address) {
        let company_id_: ID = object::id_from_address(company_address);
        let customer = Customer {
            id: object::new(ctx),
            name: name,
            customer: tx_context::sender(ctx),
            company_id: company_id_,
            balance: balance::zero<SUI>(),
        };

        transfer::share_object(customer);
    }

    // create a memo for a car

    public fun create_car_memo(
        company: &mut CarCompany,
        rental_fee: u64,
        car_name: String,
        car_type: String,
        ctx: &mut TxContext
    ): Car {
        assert!(company.company == tx_context::sender(ctx), ENotCompany);
        let car = Car {
            id: object::new(ctx),
            name: car_name,
            car_type: car_type,
            company: company.company,
            available: true
        };
        let memo = CarMemo {
            id: object::new(ctx),
            car_id: object::uid_to_inner(&car.id),
            rental_fee: rental_fee,
            company: company.company
        };

        table::add<ID, CarMemo>(&mut company.memos, object::uid_to_inner(&car.id), memo);

        car
    }

    // Book a car

    public fun book_car(
        company: &mut CarCompany,
        customer: &mut Customer,
        car: &mut Car,
        car_memo_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<SUI> {
        assert!(company.company == tx_context::sender(ctx), ENotCompany);
        assert!(customer.company_id == object::id_from_address(company.company), ENotCustomer);
        assert!(table::contains<ID, CarMemo>(&company.memos, car_memo_id), EInvalidCarBooking);
        assert!(car.company == company.company, EInvalidCar);
        assert!(car.available, EInvalidCar);
        let car_id = &car.id;
        let memo = table::borrow<ID, CarMemo>(&company.memos, car_memo_id);

        let customer_id = object::uid_to_inner(&customer.id);
        
        let rental_fee = memo.rental_fee;
        let booking_time = clock::timestamp_ms(clock);
        let booking_record = BookingRecord {
            id: object::new(ctx),
            customer_id:customer_id ,
            car_id: object::uid_to_inner(car_id),
            customer: customer.customer,
            company: company.company,
            paid_fee: rental_fee,
            rental_fee: rental_fee,
            booking_time: booking_time
        };

        transfer::public_freeze_object(booking_record);
        // deduct the rental fee from the customer balance and add it to the company balance
        assert!(rental_fee <= balance::value(&customer.balance), EInsufficientFunds);
        let amount_to_pay = coin::take(&mut customer.balance, rental_fee, ctx);
        let same_amount_to_pay = coin::take(&mut customer.balance, rental_fee, ctx);
        assert!(coin::value(&amount_to_pay) > 0, EInvalidCoin);
        assert!(coin::value(&same_amount_to_pay) > 0, EInvalidCoin);

        transfer::public_transfer(amount_to_pay, company.company);

        same_amount_to_pay
    }

    // Customer adding funds to their account

    public fun top_up_customer_balance(
        customer: &mut Customer,
        amount: Coin<SUI>,
        ctx: &mut TxContext
    ){
        assert!(customer.customer == tx_context::sender(ctx), ENotCustomer);
        balance::join(&mut customer.balance, coin::into_balance(amount));
    }

    // add the Payment fee to the company balance

    public fun top_up_company_balance(
        company: &mut CarCompany,
        customer: &mut Customer,
        car: &mut Car,
        car_memo_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ){
        // Can only be called by the customer
        assert!(customer.customer == tx_context::sender(ctx), ENotCustomer);
        let (amount_to_pay) = book_car(company, customer, car, car_memo_id, clock, ctx);
        balance::join(&mut company.balance, coin::into_balance(amount_to_pay));
    }

    // Get the balance of the company

    public fun get_company_balance(company: &CarCompany) : &Balance<SUI> {
        &company.balance
    }

    // Company can withdraw the balance

    public fun withdraw_funds(
        company: &mut CarCompany,
        amount: u64,
        ctx: &mut TxContext
    ){
        assert!(company.company == tx_context::sender(ctx), ENotCompany);
        assert!(amount <= balance::value(&company.balance), EInsufficientFunds);
        let amount_to_withdraw = coin::take(&mut company.balance, amount, ctx);
        transfer::public_transfer(amount_to_withdraw, company.company);
    }
    
    // Transfer the Ownership of the car to the customer

    public entry fun transfer_car_ownership(
        customer: &Customer,
        car: Car,
    ){
        transfer::transfer(car, customer.customer);
    }


    // Customer Returns the car ownership
    // Set the car as available again

    public fun return_car(
        company: &mut CarCompany,
        customer: &mut Customer,
        car: &mut Car,
        ctx: &mut TxContext
    ) {
        assert!(company.company == tx_context::sender(ctx), ENotCompany);
        assert!(customer.company_id == object::id_from_address(company.company), ENotCustomer);
        assert!(car.company == company.company, EInvalidCar);

        car.available = true;
    }  
}
