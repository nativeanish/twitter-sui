module Twitter {

    struct Profile {
        id: u64,
        username: string,
        email: string,
        bio: string,
        created_at: u64,
    }

    struct Tweet {
        id: u64,
        user_id: u64,
        content: string,
        created_at: u64,
        edited_at: Option<u64>, // Use Option type for edited_at
        likes: Vec<u64>, // Use Vec for likes
        retweet_count: u64, // Track retweet count
    }

    pub vector<Profile> profiles;
    pub vector<Tweet> tweets;

    pub fun create_profile(username: string, email: string, bio: string, created_at: u64) -> Option<u64> {
        if profiles.iter().any(|profile| profile.username == username || profile.email == email) {
            return None; // Username or email already exists
        }

        let user_id = profiles.len() as u64;
        let new_profile = Profile {
            id: user_id,
            username,
            email,
            bio,
            created_at,
        };

        profiles.push(new_profile);
        Some(user_id)
    }

    pub fun authenticate_user(username: string, email: string) -> Option<u64> {
        profiles.iter().find_map(|profile| {
            if profile.username == username && profile.email == email {
                Some(profile.id)
            } else {
                None
            }
        })
    }

    pub fun create_tweet(user_id: u64, content: string, created_at: u64) -> Option<u64> {
        let user_exists = profiles.get(user_id as usize).is_some();
        if !user_exists {
            return None; // User not found
        }

        let tweet_id = tweets.len() as u64;
        let new_tweet = Tweet {
            id: tweet_id,
            user_id,
            content,
            created_at,
            edited_at: None,
            likes: Vec::new(),
            retweet_count: 0,
        };

        tweets.push(new_tweet);
        Some(tweet_id)
    }

    pub fun edit_tweet(tweet_id: u64, user_id: u64, content: string, edited_at: u64) -> bool {
        tweets.get_mut(tweet_id as usize).map_or(false, |tweet| {
            if tweet.user_id == user_id {
                tweet.content = content;
                tweet.edited_at = Some(edited_at);
                true
            } else {
                false
            }
        })
    }

    pub fun delete_tweet(tweet_id: u64, user_id: u64) -> bool {
        tweets.iter().position(|tweet| tweet.id == tweet_id && tweet.user_id == user_id).map_or(false, |index| {
            tweets.remove(index);
            true
        })
    }

    pub fun like_tweet(tweet_id: u64, user_id: u64) -> bool {
        tweets.iter_mut().find(|tweet| tweet.id == tweet_id).map_or(false, |tweet| {
            if !tweet.likes.contains(&user_id) {
                tweet.likes.push(user_id);
                true
            } else {
                false
            }
        })
    }

    pub fun retweet(tweet_id: u64, user_id: u64, created_at: u64) -> Option<u64> {
        let original_tweet = tweets.get(tweet_id as usize)?;
        let retweet_id = create_tweet(user_id, original_tweet.content.clone(), created_at)?;

        let retweet_index = retweet_id as usize;
        if let Some(retweet) = tweets.get_mut(retweet_index) {
            retweet.retweet_count += 1;
        }

        Some(retweet_id)
    }

    pub fun delete_account(user_id: u64) {
        profiles.retain(|profile| profile.id != user_id);
        tweets.retain(|tweet| tweet.user_id != user_id);
    }
}
