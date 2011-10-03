module SpecHelpers
  module API
    extend ActiveSupport::Concern

    included do
      let(:application) { api }
      let(:http_headers) { {'X-Auth-Token' => access_token.token } }

      let(:api) do
        api_class.tap do |a|
          stub_warden_serializer
          stub_abstract_store
          a.instance.initializers.reject! { |initializer| skipped_initializers.include? initializer.name }

          a.instance.initialize!
        end
      end

      # TODO: REFACTOR
      # This has to be done because we're using a custom serializer to Redis
      # The right thing to do is to use Warden's serialization. This allows
      # people to use their own authentication scheme besides the built-in one
      # (and possibly spin off the built-in auth as its own gem).
      let(:stub_warden_serializer) do
        class Warden::SessionSerializer
          def store(user, scope)
          end

          def fetch(scope)
          end

          def stored?(scope)
            false
          end

          def delete(scope, user=nil)
          end
        end
      end
      let(:stub_abstract_store) do
        class ::ActionDispatch::Session::AbstractStore
          def destroy_session(env, sid, options) 
          end
        end
      end

      let(:skipped_initializers) { [:add_routing_paths, :append_assets_path, :prepend_helpers_path] }
    end
  end
end
