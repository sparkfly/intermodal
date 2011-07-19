module Intermodal
  module Rack
    class Auth
      UNAUTHORIZED = [401, {}, ""]
      IDENTITY='HTTP_X_AUTH_IDENTITY'
      KEY='HTTP_X_AUTH_KEY'

      class << self
        def valid?(env)
          env[IDENTITY] && env[KEY]
        end

        # USAGE:
        #
        # (1) Define ::AccessCredential.authenticate!(identity, key) and returns an account object
        # (2) Define ::AccessToken.generate!(account) and inserts token for authentication
        #     You can inherit from Intermodal::Auth::AccessToken
        # (3) Add to routes:
        #     match '/auth', :to => Intermodal::Rack::Auth
        
        def call(env)
          return UNAUTHORIZED unless valid?(env) && ( account = AccessCredential.authenticate!(env[IDENTITY], env[KEY]))
          access_token = AccessToken.generate!(account)
          [ 204, { 'X-Auth-Token' => access_token.to_s }, '']
        end
      end
    end
  end
end
