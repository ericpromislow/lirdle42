class ExternalInvitationsController < ApplicationController
  before_action :logged_in_user, only: %i[ create update destroy ]
  before_action :set_logged_in_user, only: %i[ create ]
  skip_before_action :verify_authenticity_token, only: %i[ update destroy ]# if :json_request

  def create
    id = params[:id]
    @user = User.find_by(id: id)
    if @user
      # idn = id.to_i
      # idx = 10 ** (Math.log10(idn).floor + 1) - idn
      @user.create_invite_digest
      # x = new_external_invitations_url
      # puts x
      url = "#{ root_url }join?code=#{id}_#{@user.invite_token}"
      flash[:info] = "Send them '#{url}' - this link expires in 2 hours"
    else
      flash.now[:danger] = "User not found (see logs)"
      Rails.logger.error("Can't find user id #{ id }")
    end
    redirect_to root_url
  end

  def edit
    # if logged in do something else
    code = params[:id]
    if code.nil?
      flash[:danger] = "No entry code supplied"
      redirect_to root_url
      return
    end
    id, token = code.split('_', 2)
    puts "QQQ: invite-controller: edit: id: #{id}, token:#{token}"
    redirect_to root_url
  end

  def update

  end

  def destroy

  end
private

end
