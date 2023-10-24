module UsersHelper

  # Not actually implementing this (it's 2023 - I know gravatars still work,
  # but it seems so unlikely that they still do)

  # Returns the Gravatar for the given user.
  def gravatar_for(user, options = { size: 80 })
    size         = options[:size]
    gravatar_id  = Digest::MD5::hexdigest('eric.promislow@gmail.com')
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    image_tag(gravatar_url, alt: user.username, class: "gravatar")
  end

end
