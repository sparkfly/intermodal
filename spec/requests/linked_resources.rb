require 'spec_helper'
require 'tsort'

describe Intermodal::ResourceController do
  include Intermodal::RSpec::LinkedResources
  include SpecHelpers::Application
  include SpecHelpers::API

  let(:api_class) do
    define_class :Api, Rails::Engine do
      include Intermodal::API
      include SpecHelpers::Epiphyte

      controllers do
        link_resources_from :items, :to => :vendors, :model => Sku
      end

      routes.draw do
        get    '/items/:id/vendors(.:format)', :to => 'items/vendors#index'
        post   '/items/:id/vendors(.:format)', :to => 'items/vendors#create'
        put    '/items/:id/vendors(.:format)', :to => 'items/vendors#update'
        delete '/items/:id/vendors(.:format)', :to => 'items/vendors#destroy'
      end
    end
  end

  context 'when implemented within an api engine' do
    link_resource :items, :to => :vendors, :with => Sku do
      let(:model_parents) { [ item ] }
      let(:model_collection) { skus; items.skus.to_sku_ids }
      let(:unlinked_targets) { Sku.make!(3, :item => item) }
      let(:skus) { item.vendors << vendors }
      let(:vendors) { Vendor.make!(3, :account => account) }

      expects_crud_for_linked_resource
    end
  end
end
