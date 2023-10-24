json.extract! user, :id, :username, :email, :is_temporary, :profile_id, :created_at, :updated_at
json.url user_url(user, format: :json)
