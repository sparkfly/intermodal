require 'spec_helper'
require 'tsort'

describe Intermodal::ResourceController do
  include Intermodal::RSpec::Resources
  include SpecHelpers::Application
  include SpecHelpers::API

  let(:api_class) do
    define_class :Api, Rails::Engine do
      include Intermodal::API
      include SpecHelpers::Epiphyte

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
