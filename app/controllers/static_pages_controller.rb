class StaticPagesController < ApplicationController
  def home
    @waiting_users = get_waiting_users
  end

  def help
  end

  def about
  end

  def contact
  end
private
  def get_waiting_users
    User.where(waiting_for_game: true).order('LOWER(username)')
  end
end
