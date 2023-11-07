class MainChannel < ApplicationCable::Channel
  def subscribed(*args)
    Rails.logger.debug("QQQ: >> MainChannel#subscribed: args: #{args}")
    stream_from "main"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    Rails.logger.debug("QQQ: >> MainChannel#unsubscribed")
  end
end
