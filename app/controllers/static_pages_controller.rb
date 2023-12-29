class StaticPagesController < ApplicationController
  def home
    @waiting_users = get_waiting_users
    user = current_user
    if user
      active_invitations = Invitation.where(to: user.id)
      if active_invitations.count > 0
        inv = active_invitations.first
        @globalInvitationMessage = { chatroom: 'main', type: 'invitation',
          message: { id: inv.id, from: inv.from, to: inv.to,
            toUsername: user.username,
            fromUsername: User.find(inv.from).username,
          } }
      end
    end
  end

  def help
  end

  def about
  end

  def contact
  end
private
  def get_waiting_users
    User.where(waiting_for_game: true).order('LOWER(username)')
  end
end
