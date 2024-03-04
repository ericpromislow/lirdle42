class ExternalInvitationsController < ApplicationController
  before_action :cor, only: %i[  destroy update ]
  before_action :logged_in_user
  skip_before_action :verify_authenticity_token, only: %i[ update destroy ]# if :json_request

  def create
    i_params = invitation_params
    from_id = i_params[:from]
    from_user = User.find(from_id) rescue nil
    if !from_user
      flash[:danger] = 'Incomplete invitation'
    else
      clear_old_invitations(from_id, -1, from_user, nil)
      oicount = Invitation.where(to: from_id).count
      if oicount > 0
        flash[:danger] = "#{ from_user.username } has an invitation to another game."
      else
        
        invitation = ExternalInvitation.create(i_params)
    end
  end

  def update
  end

  def delete
  end
private
  def invitation_params
    p1 = params.permit(:from, :authenticity_token, :commit) { from: p1[:from] }
  end
  def cor
    headers["Access-Control-Allow-Origin"]  = "*"
    headers["Access-Control-Allow-Methods"] = %w{GET POST PUT DELETE}.join(",")
    headers["Access-Control-Allow-Headers"] = %w{Origin Accept Content-Type X-Requested-With X-CSRF-Token}.join(",")
    #head(:ok) if request.request_method == "DELETE" && ENV['RAILS_ENV'] != 'test'
  end

end
