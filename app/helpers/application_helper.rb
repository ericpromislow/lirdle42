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

  def update_waiting_users
    users = User.where(waiting_for_game: true).select(:id, :username, :email).order('LOWER(username)')
    ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'waitingUsers', message: users.to_a }
  end

end
