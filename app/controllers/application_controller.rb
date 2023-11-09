class ApplicationController < ActionController::Base
  include SessionsHelper

private # should be protected?

  def admin_or_in_game
    return if @user.admin?
    return if @game.playerA == @user || @user == @game.playerB

    flash[:danger] = "You're not playing this game"
    redirect_to request.referrer || root_url
  end

  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = "Please log in"
      redirect_to login_url
    end
  end

  def set_logged_in_user
    @user = current_user
  end
end
