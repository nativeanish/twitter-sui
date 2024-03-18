module twitter::main {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{TxContext, sender};
    use sui::coin::{Self, Coin, CoinMetadata};
    use sui::balance::{Self, Balance};
    use sui::sui::{SUI};
    use sui::clock::{Self, Clock, timestamp_ms};

    use std::option::{Self, Option};
    use std::vector::{Self};
    use std::string::{Self, String};

    const ERROR_NOT_OWNER: u64 = 0;
    const ERROR_ALREADY_TWITTED: u64 = 0;

    struct Profile has key, store  {
        id: UID,
        owner: address,
        username: String,
        email: String,
        bio: String,
        created_at: u64,
        tweets: vector<Tweet>
    }

    struct Tweet has copy, drop, store {
        user_id: u64,
        content: String,
        created_at: u64,
        edited_at: Option<u64>, // Use Option type for edited_at
        likers: vector<address>,
        likes_count: u64, // Use Vec for likes
        retweet_count: u64, // Track retweet count
    }


    public fun new_profile(username: String, email: String, bio: String, created_at: u64, ctx: &mut TxContext)  {
        // create new profile 
        let profile = Profile {
            id: object::new(ctx),
            owner: sender(ctx),
            username,
            email,
            bio,
            created_at,
            tweets: vector::empty()
        };
        transfer::share_object(profile);
     }

    public fun create_tweet(self: &mut Profile, user_id: u64, content: String, clock: &Clock, ctx: &mut TxContext) {
        assert!(sender(ctx) == self.owner, ERROR_NOT_OWNER);

        let tweet = Tweet {
            user_id: user_id,
            content: content,
            created_at: timestamp_ms(clock),
            edited_at: option::none(),
            likers: vector::empty(),
            likes_count: 0,
            retweet_count: 0,
        };
        vector::push_back(&mut self.tweets, tweet);
    }

    public fun edit_tweet(self: &mut Profile, index: u64, _id: u64, user_id: u64, content: String, clock: &Clock)  {
        let tweet = vector::borrow_mut(&mut self.tweets, index);
        tweet.user_id = user_id;
        tweet.content = content;
        option::fill(&mut tweet.edited_at, timestamp_ms(clock));
    }

    public fun delete_tweet(self: &mut Profile, index: u64, ctx: &mut TxContext) {
        assert!(self.owner == sender(ctx), ERROR_NOT_OWNER);
        vector::remove(&mut self.tweets, index);
    }

    public fun like_tweet(self: &mut Profile, index: u64, ctx: &mut TxContext) {
        let tweet = vector::borrow_mut(&mut self.tweets, index);
        assert!(!vector::contains<address>(&tweet.likers, &sender(ctx)), ERROR_ALREADY_TWITTED);
        tweet.likes_count = tweet.likes_count + 1;
        vector::push_back(&mut tweet.likers, sender(ctx));
    }
    
}
