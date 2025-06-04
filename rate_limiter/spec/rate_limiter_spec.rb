# frozen_string_literal: true

require_relative '../rate_limiter'

RSpec.describe RateLimiter do
  let(:limiter) { RateLimiter.new(30, 3) }

  describe '#allow_request?' do
    it 'allows up to 3 requests per 30 seconds' do
      expect(limiter.allow_request?(10, 1)).to be true
      expect(limiter.allow_request?(15, 1)).to be true
      expect(limiter.allow_request?(20, 1)).to be true

      # 4th request within the same window should be denied
      expect(limiter.allow_request?(25, 1)).to be false
    end

    it 'allows a new request after the window expires' do
      limiter.allow_request?(10, 1)
      limiter.allow_request?(15, 1)
      limiter.allow_request?(20, 1)

      # 31 seconds later, the first request is now out of the window
      expect(limiter.allow_request?(41, 1)).to be true
    end

    it 'treats each user independently' do
      limiter.allow_request?(10, 1)
      limiter.allow_request?(10, 2)
      limiter.allow_request?(11, 1)
      limiter.allow_request?(11, 2)
      limiter.allow_request?(12, 1)
      limiter.allow_request?(12, 2)

      # User 1 has made 3 requests, User 2 has made 3 requests
      expect(limiter.allow_request?(13, 1)).to be false
      expect(limiter.allow_request?(13, 2)).to be false
    end
  end

  describe '#prune_inactive_users!' do
    it 'removes users with only expired timestamps' do
      limiter.allow_request?(10, 1)
      limiter.allow_request?(11, 2)
      limiter.allow_request?(12, 3)

      limiter.prune_inactive_users!(100)

      expect(limiter.instance_variable_get(:@user_requests).keys).to be_empty
    end

    it 'retains users with recent timestamps' do
      limiter.allow_request?(71, 1)
      limiter.allow_request?(72, 2)
      limiter.allow_request?(10, 3)

      limiter.prune_inactive_users!(100)

      expect(limiter.instance_variable_get(:@user_requests).keys).to contain_exactly(1, 2)
    end
  end

  context 'additional cases' do
    # NOTE: The tests above cover the cases tested here, but I am including
    # this test to demonstrate that the specific case from the assessment prompt passes, explicity.
    it 'passes the sample case explicitely given in the assessment prompt' do
      expect(limiter.allow_request?(1700000010, 1)).to be true
      expect(limiter.allow_request?(1700000011, 2)).to be true
      expect(limiter.allow_request?(1700000020, 1)).to be true
      expect(limiter.allow_request?(1700000035, 1)).to be true
      expect(limiter.allow_request?(1700000040, 1)).to be true
    end
  end
end
