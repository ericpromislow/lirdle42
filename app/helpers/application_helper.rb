module ApplicationHelper

  APPNAME = "lirdle42"
  NUM_FREE_LOGINS = 10 # After this they have to activate their login

  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = APPNAME.capitalize
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end

  def update_waiting_users(cuser=nil)
    users = User.where(waiting_for_game: true).select(:id, :username, :email).order('LOWER(username)')
    users = users.filter{ |u| cuser&.id == u.id || !u.in_game }.map do |user|
      u = { id: user.id, username: user.username}
      if user.image&.attached?
        u[:image_url] = Rails.application.routes.url_helpers.rails_blob_path(user.image, only_path: true)
      else
        gravatar_id  = Digest::MD5::hexdigest(user.email)
        gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=40"
        u[:image_url] = gravatar_url
      end
      u
    end
    ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'waitingUsers', message: users.to_a, userID: cuser&.id }
  end

end
