class AccountActivationsController < ApplicationController
  def create
    @user = user = User.find(params[:user][:id])
    if !user
      flash[:error] = "Can't find the user"
    elsif !current_user
      flash[:error] = "User #{ user.username } needs to be logged in to start account activation"
    elsif user != current_user
      flash[:error] = "user #{ user.username } can't activate user #{ current_user.username }"
    elsif user.activated?
      flash[:error] = "user #{ user.username } is already activated"
    else
      user.activation_token = User.new_token
      user.activation_digest = User.digest(user.activation_token)
      if !user.save
        flash[:error] = "user #{ user.username } can't be updated"
      else
        UserMailer.account_activation(user).deliver_now
        flash[:info] = "Please check your email (for #{ user.email }) to activate your account."
      end
    end
    redirect_to root_url
  end

  def edit
    user = User.find_by(email: params[:email])
    if !user
      msg = %Q[Can't find a user with email "#{ params[:email] }"]
      flash[:danger] = msg
    elsif user.activated?
      msg = "User #{ user.username } is already activated"
      flash[:danger] = msg
    elsif !user.authenticated?(:activation, params[:token])
      msg = "Invalid activation link #{  params[:token] } for user #{ user.username }. Where'd you get this from?"
      flash[:danger] = msg
    else
      user.update_attribute(:activated, true)
      user.update_attribute(:activated_at, Time.zone.now)
      log_in user
      flash[:success] = "Account activated"
    end
    redirect_to root_url
  end
end
