class InvitationsController < ApplicationController
# class InvitationsController < ActionController::API
#   include ActionController::MimeResponds
  before_action :cor, only: %i[  destroy update ]
  before_action :logged_in_user, only: %i[ create update destroy ]
  skip_before_action :verify_authenticity_token, only: %i[ update destroy ]# if :json_request
  def create
    i_params = invitation_params
    from_id = i_params[:from]
    to_id = i_params[:to]
    from_user = User.find(from_id) rescue nil
    to_user = User.find(to_id) rescue nil
    if !from_user || !to_user
      flash[:danger] = 'Incomplete invitation'
    elsif from_user != current_user
      flash[:danger] = "Third-party invitation not supported"
    else
      other_invitations = Invitation.where(to: from_id)
      oicount = other_invitations.count
      if oicount > 0
        flash[:danger] = "There #{ "is".pluralize(oicount) } currently #{ oicount } #{ "invitation".pluralize(oicount) } to #{ from_user.username }"
      else
        invitation = Invitation.new(i_params)
        if invitation.save
          ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'invitation',
                                                 message: { id: invitation.id, from: from_id, to: to_id,
                                                            toUsername: to_user.username,
                                                            fromUsername: from_user.username,
                                                 } }
          head :ok
          return
        else
          flash[:danger] = "Failed to save the invitation: #{ invitation.errors.full_messages }"
        end
      end
    end
    redirect_to request.referrer || root_url
  end
  def update
    begin
      do_update
    rescue
      $stderr.puts "What ahoppen?"
    end
  end

  def do_update
    invitation = Invitation.find(params[:id])
    originator_id = params[:originator]
    to_user = User.find(invitation.to)
    if originator_id.to_i != to_user.id
      head :not_acceptable
    else
      reason = params[:reason]
      from_id = invitation.from
      from_user = User.find(from_id)
      invitation.destroy!
      if reason == 'declined' || reason == 'accepted'
        ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'invitationEnding',
                                               message: { id: invitation.id, from: from_id, to: originator_id,
                                                          toUsername: to_user.username,
                                                          fromUsername: from_user.username,
                                                          message: reason
                                               } }
        head :ok
        return
      end
    end
    head :bad_request
  end

  def destroy
    cuser = current_user
    if !cuser
      flash[:danger] = "Not logged in"
      head :forbidden
      return
    end
    invitation_id = params[:id]
    invitation = Invitation.find(invitation_id)
    if !invitation
      flash[:danger] = "Can't find the invitationitation"
      head :not_found
      return
    end
    if ![invitation.from, invitation.to].include?(cuser.id)
      flash[:danger] = 'forbidden'
      head :forbidden
      return
    end
    to_id = invitation.to
    from_id = invitation.from
    from_user = User.find(from_id)
    to_user = User.find(to_id)
    invitation.destroy
    # puts "QQQ: flash: #{ params[:flash] }, reason: #{ params[:reason] }"
    if params[:flash] || params[:reason] == 'cancelled'
      ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'invitationCancelled',
                                             message: { id: invitation_id, from: from_id, to: to_id,
                                                        toUsername: to_user.username,
                                                        fromUsername: from_user.username,
                                                        message: params[:flash]
                                             } }
      head :ok
      return
    elsif params[:reason] == 'accepted'
      ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'invitationAccepted',
                                             message: { id: invitation_id, to: from_id, game_id: params[:game_id]
                                             } }
    else
      puts "Ignoring reason #{ params[:reason] }" if !params[:reason].blank?
    end
    head :ok

  end
private
  def invitation_params
    params.permit(:from, :to)
  end
  def cor
    headers["Access-Control-Allow-Origin"]  = "*"
    headers["Access-Control-Allow-Methods"] = %w{GET POST PUT DELETE}.join(",")
    headers["Access-Control-Allow-Headers"] = %w{Origin Accept Content-Type X-Requested-With X-CSRF-Token}.join(",")
    #head(:ok) if request.request_method == "DELETE" && ENV['RAILS_ENV'] != 'test'
  end

end
