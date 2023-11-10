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

  def set_game_variables(game)
    gameStateA = GameState.find(game.gameStateA)
    gameStateB = GameState.find(game.gameStateB)

    if game.playerA == @user
      @other_player = User.find(gameStateB.playerID)
    else
      @other_player = User.find(gameStateA.playerID)
    end
    if !@game_state
      if game.playerA == @user
        @game_state = gameStateA
        @other_state = gameStateB
      else
        @game_state = gameStateB
        @other_state = gameStateA
      end
    else
      @other_state = @game_state == gameStateA ? gameStateB : gameStateA
    end
    # Game states are more complicated because lies work on the other player's game-state
  end

  def set_logged_in_user
    @user = current_user
  end
end
