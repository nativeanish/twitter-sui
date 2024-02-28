enum Result<T> {
    Ok(T),
    Err(String),
}

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

    // Function to check if a user exists
    pub fun user_exists(user_id: u64): bool {
        profiles.get(user_id as usize).is_some()
    }

    // Function to create a profile with result type
    pub fun create_profile(username: string, email: string, bio: string, created_at: u64): Result<u64> {
        if profiles.iter().any(|profile| profile.username == username || profile.email == email) {
            return Err("Username or email already exists".to_string());
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
        Ok(user_id)
    }

    // Function to authenticate a user with result type
    pub fun authenticate_user(username: string, email: string): Result<u64> {
        profiles.iter().find_map(|profile| {
            if profile.username == username && profile.email == email {
                Some(profile.id)
            } else {
                None
            }
        }).map_or(Err("User not found".to_string()), |id| Ok(id))
    }

    // ... (similar updates for other functions)

    // Function to delete account with result type
    pub fun delete_account(user_id: u64): Result<()> {
        if let Some(index) = profiles.iter().position(|profile| profile.id == user_id) {
            profiles.remove(index);
            tweets.retain(|tweet| tweet.user_id != user_id);
            Ok(())
        } else {
            Err("User not found".to_string())
        }
    }
}
