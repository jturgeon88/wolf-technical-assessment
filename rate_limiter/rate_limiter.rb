# frozen_string_literal: true

class RateLimiter
  def initialize(time_window, max_requests)
    @time_window = time_window
    @max_requests = max_requests
    @user_requests = Hash.new { |h, k| h[k] = [] }
  end

  def allow_request?(timestamp, user_id)
    queue = @user_requests[user_id]

    while queue.any? && queue.first <= timestamp - @time_window
      queue.shift
    end

    if queue.size < @max_requests
      queue << timestamp
      true
    else
      false
    end
  end
end
