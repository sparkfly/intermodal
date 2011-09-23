module Intermodal
  module Models
    module AccessToken
      extend ActiveSupport::Concern

      included do
        attr_accessor :account_id, :token
        cattr_accessor :redis

        EXPIRATION_PERIOD = 24 unless defined?(EXPIRATION_PERIOD)# hours
        TOKEN_SIZE = 32        unless defined?(TOKEN_SIZE)
        REDIS = Redis.new      unless defined?(REDIS)

        def self.establish_connection!(address = 'localhost:6379')
          host, port = address.split(':')

          host ||= 'localhost'
          port = (port || 6379).to_i

          self.redis = Redis.new(:host => host, :port => port)
        end

        def self.authenticate!(token)
          return nil unless account_id = self.redis.get("auth:#{token.to_s}")
          ::Account.where(:id => account_id).first
        end

        def self.generate!(account)
          token = new(:account_id => account.id)
          begin
            token.token = SecureRandom.hex(TOKEN_SIZE)
          end until token.valid?
          return token if token.save
        end

        def self.count
          redis.keys('auth:*').size
        end

        def initialize(opts)
          @account_id = opts[:account_id]
        end

        def redis_key
          "auth:#{self.token.to_s}"
        end

        def valid?
          !redis.get(redis_key)
        end

        def save
          redis.setex(redis_key, EXPIRATION_PERIOD.hours, account_id)
        end

        def to_s; self.token; end
      end
    end
  end
end
