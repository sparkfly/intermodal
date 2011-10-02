require 'spec_helper'
require 'tsort'

describe Intermodal::ResourceController do
  include Intermodal::RSpec::Resources
  include SpecHelpers::Application

  let(:application) { api }

  let(:http_headers) { {'X-Auth-Token' => access_token.token } }

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
  let(:api_class) do
    define_class :Api, Rails::Engine do
      include Intermodal::API

      def initializers
        @initializers ||= self.class.initializers_for(self)
      end

      def initialize!
        raise "Application has been already initialized." if @initialized
        run_initializers(self)
        @initialized = true
        self
      end

      def config
        @config ||= Rails::Engine::Configuration.new(File.dirname(__FILE__))
      end

      # TODO:
      # For some reason, Rails::Railstie::Configurable does not
      # pick up routes within the engine. I don't know if this
      # has to do with the way I loaded the API in specs, or
      # if there is a bug in Rails. I'm leaving this here for
      # now.
      def self.routes
        instance.routes
      end

      def routes
        @routes ||= ActionDispatch::Routing::RouteSet.new
        @routes.append(&Proc.new) if block_given?
        @routes
      end

      map_data do
        presentation_for :item do
          presents :id
          presents :name
          presents :description
        end

        acceptance_for :item do
          accepts :name
          accepts :description
        end
      end

      controllers do
        resources :items
      end

      routes.draw do
        resources :items
      end
    end
  end

  let(:api) do
    api_class.tap do |a|
      stub_warden_serializer
      stub_abstract_store
      a.instance.initializers.reject! { |initializer| skipped_initializers.include? initializer.name }

      a.instance.initialize!
      a.load_controllers!
    end
  end

  context 'when implemented within an api engine' do
    let(:model_factory_options) { (model_parent ? { parent_names.last.to_s.singularize => model_parent } : {:account => account} ) }
    let(:model_collection) do
      3.times { model.make!(model_factory_options) }
      (model_parent ? model.by_parent(model_parent) : model.by_account(account) )
    end

    resources :items do
      given_create_attributes :name => 'New Item', :description => 'Ipsum Lorem', :account_id => 1
      given_update_attributes :name => 'Updated Merchant', :description => 'Lorem Ipsum'

      expects_resource_crud
    end
  end
end
