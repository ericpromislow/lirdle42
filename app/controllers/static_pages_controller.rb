class StaticPagesController < ApplicationController
  def home
    @waiting_users = User.where(waiting_for_game: true).order('LOWER(username)')
  end

  def help
  end

  def about
  end

  def contact
  end
end
