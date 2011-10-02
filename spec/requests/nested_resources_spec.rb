require 'spec_helper'
require 'tsort'

describe Intermodal::NestedResourceController do
  include Intermodal::RSpec::Resources
  include SpecHelpers::Application
  include SpecHelpers::API

  let(:api_class) do
    define_class :Api, Rails::Engine do
      include Intermodal::API
      include SpecHelpers::Epiphyte

      map_data do
        presentation_for :part do
          presents :id
          presents :item_id
          presents :description
        end

        acceptance_for :part do
          accepts :name
        end
      end

      controllers do
        nested_resources :items, :parts
      end

      routes.draw do
        resources :items do
          resources :parts, :controller => 'items/parts'
        end
      end
    end
  end

  context 'when implemented within an api engine' do
    let(:model_factory_options) { (model_parent ? { parent_names.last.to_s.singularize => model_parent } : {:account => account} ) }
    let(:model_collection) do
      3.times { model.make!(model_factory_options) }
      (model_parent ? model.by_parent(model_parent) : model.by_account(account) )
    end

    resources [:items, :parts] do
      let(:model_parents) { [ item ] }
      let(:model) { Part }

      given_create_attributes :name => 'New Part', :item_id => 1
      given_update_attributes :name => 'Updated Part'

      expects_resource_crud
    end
  end
end
