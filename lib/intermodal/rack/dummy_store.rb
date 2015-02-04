require 'action_dispatch/middleware/session/abstract_store'

module Intermodal
  module Rack
    # A dummy store that does nothing, but satisfies Warden's session store requirement
    # This allows us to use the x_auth_token strategy
    class DummyStore < ::ActionDispatch::Session::AbstractStore

      def get_session(env, sid)
        [nil, nil]
      end

      # Set a session in the cache.
      def set_session(env, sid, session, options)
        nil
      end

      # Remove a session from the cache.
      def destroy_session(env, sid, options)
        nil
      end
    end
  end
end
