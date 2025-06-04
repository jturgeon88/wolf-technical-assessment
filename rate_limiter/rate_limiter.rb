# frozen_string_literal: true

class RateLimiter
  def initialize(time_window, max_requests)
    @time_window = time_window
    @max_requests = max_requests
    @user_requests = Hash.new { |h, k| h[k] = [] }
  end

  def allow_request?(timestamp, user_id)
    queue = @user_requests[user_id]
    prune_old_requests!(queue, timestamp)

    if queue.size < @max_requests
      queue << timestamp
      true
    else
      false
    end
  end

  # For optional use. Frees memory by removing users whose request history
  # has expired. Useful in large, long-lived systems to prevent excessive memory
  # growth from inactive users.
  def prune_inactive_users!(current_time)
    @user_requests.delete_if do |_, timestamps|
      timestamps.last && timestamps.last <= current_time - @time_window
    end
  end

  private

  def prune_old_requests!(queue, timestamp)
    while queue.any? && queue.first <= timestamp - @time_window
      queue.shift
    end
  end
end
