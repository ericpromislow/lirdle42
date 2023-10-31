class UsersController < ApplicationController
  # Does these before_actions in order of appearance here:
  before_action :set_user, only: %i[ show edit update destroy ]
  before_action :logged_in_user, only: %i[ index edit update destroy ]
  before_action :allow_admins_only, only: %i[ destroy  ]
  before_action :correct_user, only: %i[ edit update  ]

  # GET /users or /users.json
  def index
    # TODO: List only activated users eventually who are also logged in
    @users = User.order('LOWER(username)').paginate(:page => params[:page], :per_page => 10)
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = "Welcome, #{ @user.username }"
      redirect_to root_url
    else
      flash[:error] = "errors"
      render 'new'
    end

    # respond_to do |format|
    #   if @user.save
    #     flash[:success] = "Welcome, #{ @user.username }"
    #     redirect_to @user #, notice: "User was successfully created."
    #     # format.json { render :show, status: :created, location: @user }
    #   else
    #     render 'new'
    #     # format.html { render :new, status: :unprocessable_entity }
    #     # format.json { render json: @user.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    if @user.update(updatable_params)
      image_field = params[:user][:image]
      if image_field
        begin
          @user.image.attach(image_field)
          flash[:success] = "User #{@user.username}  was successfully updated."
        rescue # SQLite3::BusyException => ex
          puts "Error trying to attach image: #{ $! }"
          flash[:error] = "Error accessing image database. Please try later."
        end
      end
      redirect_to user_url(@user)
    else
      flash[:error] = "User #{@user.username} not updated: #{ @user.errors.full_messages }"
      render 'edit'
    end
    # respond_to do |format|
    #   if @user.update(user_params)
    #     format.html { redirect_to user_url(@user), notice: "User #{@user.username}  was successfully updated." }
    #     format.json { render :show, status: :ok, location: @user }
    #   else
    #     format.html { render :edit, status: :unprocessable_entity }
    #     format.json { render json: @user.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    if @user == current_user
      flash[:error] = "User #{ @user.username } can't delete themselves"
    else
      @user.destroy
      flash[:success] = "User #{ @user.username } is swimming with the fishes"
    end
    redirect_to users_url
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = "Please log in"
      redirect_to login_url
    end
  end

  # Only allow a list of trusted parameters through.
  def  user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :admin, :image)
  end

  def updatable_params
    params.require(:user).permit(:username, :password, :password_confirmation, :image)
  end

  def correct_user
    redirect_to(root_url) unless current_user?(User.find(params[:id]))
  end

  def current_user?(user)
    user && user == current_user
  end

  def allow_admins_only
    redirect_to(root_url) if !current_user&.admin
  end
end
