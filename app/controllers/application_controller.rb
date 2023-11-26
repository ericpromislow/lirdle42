class ApplicationController < ActionController::Base
  include SessionsHelper

private # should be protected?

  def admin_or_in_game
    return if @user.admin?
    return if @game.game_states.map(&:user).include?(@user)

    flash[:danger] = "You're not playing this game"
    redirect_to root_url
  end

  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = "Please log in"
      redirect_to login_url
    end
  end

  def set_game_variables(game)
    gs1, gs2 = game.game_states

    if gs1.user == @user
      @other_player = gs2.user
    else
      @other_player = gs1.user
    end
    if !@game_state
      if gs1.user == @user
        @game_state, @other_state = game.game_states
      else
        @other_state, @game_state = game.game_states
      end
    elsif @game_state.user == gs1.user
      @other_state = gs2
    else
      @other_state = gs1
      # @other_state = gs2.user == @user ? gs2 : gs1
    end
    # Game states are more complicated because lies work on the other player's game-state
  end

  def set_logged_in_user
    @user = current_user
  end

  def tell_player_to_reload_game(from_id, to_id, game_id)
    ActionCable.server.broadcast 'main', {
      chatroom: 'main',
      type: 'reloadGame',
      message: { game_id: game_id, from: from_id, to: to_id } }
  end
end
