class GamesController < ApplicationController
  before_action :set_game, only: %i[ show edit update destroy ]
  before_action :logged_in_user, only: %i[ index create edit show update destroy ]
  before_action :set_logged_in_user, only: %i[ index create edit show update destroy ]
  before_action :must_be_admin, only: %i[index]
  before_action :admin_or_in_game, only: %i[ edit show update destroy ]

  # GET /games or /games.json
  def index
    @games = Game.all.paginate(:page => params[:page], :per_page => 10)
  end

  # GET /games/1 or /games/1.json
  def show
  end

  # # GET /games/new
  # def new
  #   @game = Game.new
  # end

  # GET /games/1/edit
  def edit
  end

  # POST /games or /games.json
  def create
    gp = game_params
    if ![gp[:playerA], gp[:playerB]].include?(@user.id.to_s) && !@user.admin
      flash[:danger] = "Can't create a game for others"
      redirect_to request.referrer || root_url
      return
    end
    @game = Game.new(game_params)
    @game.candidateWordsForA = "abcde:fghij:klmno"
    @game.candidateWordsForB = "pqrst:uvwxy:zaaaa"
    @game.wordIndexForA = 0
    @game.wordIndexForB = 0

    respond_to do |format|
      if @game.save
        format.html { redirect_to game_url(@game), notice: "Game was successfully created." }
        format.json { render :show, status: :created, location: @game }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /games/1 or /games/1.json
  def update
    gp = update_params
    if ((gp[:playerA] && gp[:playerA] != @game.playerA.to_s) ||
      (gp[:playerB] && gp[:playerB] != @game.playerB.to_s))
      flash[:danger] = "Can't change players of a created game"
      redirect_to request.referrer || game_url(@game)
      return
    end
    respond_to do |format|
      if @game.update(gp)
        format.html { redirect_to game_url(@game), notice: "Game was successfully updated." }
        format.json { render :show, status: :ok, location: @game }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /games/1 or /games/1.json
  def destroy
    @game.destroy

    respond_to do |format|
      format.html { redirect_to games_url, notice: "Game was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_game
    @game = Game.find(params[:id])
  end

  def set_logged_in_user
    @user = current_user
  end

  def must_be_admin
    if !@user.admin
      flash[:danger] = "Admin only"
      redirect_to request.referrer || root_url
    end
  end

  def admin_or_in_game
    return if @user.admin?
    return if @game.playerA == @user || @user == @game.playerB
    flash[:danger] = "You're not playing this game"
    redirect_to request.referrer || root_url
  end

  # Only allow a list of trusted parameters through.
  def game_params
    params.require(:game).permit(:playerA, :playerB)
  end
  def update_params
    params.require(:game).permit(:stateA, :stateB, :playerA, :playerB, :candidateWordsForA, :candidateWordsForB, :wordIndexForA, :wordIndexForB, :finalWordForA, :finalWordForB)
  end
end
