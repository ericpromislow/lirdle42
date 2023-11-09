class GameStatesController < ApplicationController
  before_action :logged_in_user
  before_action :set_game_state
  before_action :set_logged_in_user
  before_action :admin_or_own_state

  # PATCH/PUT /games/1 or /games/1.json
  def update
    @game = @game_state.game
    if !@game
      flash[:danger] = "No game found"
      redirect_to request.referrer || root_url
      return
    end
    if @game_state.playerID != @user.id
      flash[:danger] = "You can't change someone else's game state"
      redirect_to request.referrer || root_url
      return
    end
    gp = update_params
    respond_to do |format|
      if @game_state.update(gp)
        format.html { redirect_to game_url(@game), notice: "GameState was successfully updated." }
        format.json { render :show, status: :ok, location: @game }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @game_state.errors, status: :unprocessable_entity }
      end
    end
  end

private
  def admin_or_own_state
    return if @user.admin?
    return if @game_state.playerID == @user.id

    $stderr.puts("QQQ: This isn't your part of the game!!")
    flash[:danger] = "Ummm that's cheating"
    redirect_to request.referrer || root_url
  end

  def set_game_state
    @game_state = GameState.find(params[:id])
  end

  def update_params
    params.permit(:state, :wordIndex, :finalWord)
  end
end
