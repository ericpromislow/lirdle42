class PasswordResetsController < ApplicationController
  before_action :get_user, only: [:edit, :update]
  before_action :valid_user, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]

  def new
  end

  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = "Email sent with password-reset instructions"
      redirect_to root_url
    else
      shortEmail = params[:password_reset][:email]
      shortEmail = "#{shortEmail[0...50]...}" if shortEmail.size > 50
      flash.now[:danger] = "Email address #{shortEmail} not found"
      render 'new'
    end
  end

  def edit
  end

  def update
    if params[:user][:password].empty?
      @user.errors.add(:password, "can't be empty")
      render 'edit'
    elsif @user.update(user_params)
      log_in @user
      @user.update_attribute(:reset_digest, nil)
      flash[:success] = "Password for #{@user.username} has been reset."
      redirect_to root_url
    else
      # Something else should have set the flash
      render 'edit'
    end
  end

private
  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  # Before-filters
  #
  def check_expiration
    if @user.password_reset_expired?
      flash[:danger] = "Password reset has expired."
      redirect_to new_password_reset_url
    end
  end

  def get_user
    @user = User.find_by(email: params[:email])
  end

  def valid_user
    shortEmail = params[:email]
    shortEmail = "#{shortEmail[0...50]...}" if shortEmail.size > 50
    if !@user
      flash[:danger] = "Email address #{shortEmail} not found"
    elsif !@user.activated?
      flash[:danger] = "User #{shortEmail} isn't activated yet"
    elsif !@user.authenticated?( :reset, params[:id])
      msg = "Invalid password-reset link for user #{ @user.username }. Where'd you get this from?"
      flash[:danger] = msg
    else
      return
    end
    redirect_to root_url
  end
end
