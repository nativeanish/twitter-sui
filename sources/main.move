// Define module Twitter
module Twitter {

    // Struct to represent a user's profile
    struct Profile {
        id: u64,
        username: string,
        email: string,
        bio: string,
        created_at: u64,
    }

    // Struct to represent a tweet
    struct Tweet {
        id: u64,
        user_id: u64,
        content: string,
        created_at: u64,
        edited_at: u64,
        likes: vector<u64>, // List of user IDs who liked the tweet
    }

    // Vector to store user profiles
    public vector<Profile> profiles;

    // Vector to store tweets
    public vector<Tweet> tweets;

    // Function to create a user profile
    public fun create_profile(username: string, email: string, bio: string, created_at: u64): u64 {
        // Check if username or email already exists
        for profile in &profiles {
            if profile.username == username {
                return 0; // Username already exists
            }
            if profile.email == email {
                return 0; // Email already exists
            }
        }

        // Generate unique user ID
        let user_id = profiles.len() as u64;

        // Create new profile
        let new_profile = Profile {
            id: user_id,
            username: username,
            email: email,
            bio: bio,
            created_at: created_at,
        };

        // Add profile to vector
        profiles.push(new_profile);

        user_id
    }

    // Function to authenticate user
    public fun authenticate_user(username: string, email: string): u64 {
        for profile in &profiles {
            if profile.username == username && profile.email == email {
                return profile.id;
            }
        }
        0 // User not found
    }

    // Function to create a tweet
    public fun create_tweet(user_id: u64, content: string, created_at: u64): u64 {
        // Check if user exists
        if user_id >= profiles.len() as u64 {
            return 0; // User not found
        }

        // Generate unique tweet ID
        let tweet_id = tweets.len() as u64;

        // Create new tweet
        let new_tweet = Tweet {
            id: tweet_id,
            user_id: user_id,
            content: content,
            created_at: created_at,
            edited_at: 0,
            likes: vec[], // Initialize empty list of likes
        };

        // Add tweet to vector
        tweets.push(new_tweet);

        tweet_id
    }

    // Function to edit a tweet
    public fun edit_tweet(tweet_id: u64, user_id: u64, content: string, edited_at: u64) {
        // Check if tweet exists
        if tweet_id >= tweets.len() as u64 {
            return; // Tweet not found
        }

        // Check if user is authorized to edit the tweet
        if tweets[tweet_id as usize].user_id != user_id {
            return; // User is not authorized to edit this tweet
        }

        // Edit tweet
        let mut tweet = &mut tweets[tweet_id as usize];
        tweet.content = content;
        tweet.edited_at = edited_at;
    }

    // Function to get a tweet
    public fun get_tweet(tweet_id: u64): Option<Tweet> {
        // Check if tweet exists
        if tweet_id >= tweets.len() as u64 {
            return None; // Tweet not found
        }

        Some(tweets[tweet_id as usize])
    }

    // Function to delete a tweet
    public fun delete_tweet(tweet_id: u64, user_id: u64) {
        // Check if tweet exists
        if tweet_id >= tweets.len() as u64 {
            return; // Tweet not found
        }

        // Check if user is authorized to delete the tweet
        if tweets[tweet_id as usize].user_id != user_id {
            return; // User is not authorized to delete this tweet
        }

        // Delete tweet
        tweets.swap_remove(tweet_id as usize);
    }

    // Function to like a tweet
    public fun like_tweet(tweet_id: u64, user_id: u64) {
        // Check if tweet exists
        if tweet_id >= tweets.len() as u64 {
            return; // Tweet not found
        }

        // Check if user has already liked the tweet
        let tweet = &mut tweets[tweet_id as usize];
        for liked_user_id in &tweet.likes {
            if *liked_user_id == user_id {
                return; // User has already liked this tweet
            }
        }

        // Like tweet
        tweet.likes.push(user_id);
    }

    // Function to retweet a tweet
    public fun retweet(tweet_id: u64, user_id: u64, created_at: u64) -> u64 {
        // Check if tweet exists
        if tweet_id >= tweets.len() as u64 {
            return 0; // Tweet not found
        }

        // Get original tweet
        let original_tweet = tweets[tweet_id as usize];

        // Create retweet
        let retweet_id = create_tweet(user_id, original_tweet.content, created_at);

        retweet_id
    }

    // Function to delete a Twitter account
    public fun delete_account(user_id: u64) {
        // Check if user exists
        if user_id >= profiles.len() as u64 {
            return; // User not found
        }

        // Remove user profile
        profiles.swap_remove(user_id as usize);

        // Remove user's tweets
        for i in (0..tweets.len()).rev() {
            if tweets[i].user_id == user_id {
                tweets.swap_remove(i);
            }
        }
    }
}
