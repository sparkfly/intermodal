require 'spec_helper'

describe Intermodal::Proxies::WillPaginate::Collection do
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
      end

      controllers do
      end

      routes.draw do
      end
    end
  end

  describe '#as_json' do
    subject { presented_collection }
    let(:presenter) { api_class.presenters[:item] }
    let(:collection) { Item.make!(3, :account => account) }
    let(:paginated_collection) { collection; Item.paginate :page => 1 }
    let(:presented_collection) { paginated_collection.as_json :presenter => presenter }

    it 'should present page' do
      subject[:page].should_not be_nil
    end

    it 'should present per_page' do
      subject[:per_page].should_not be_nil
    end

    it 'should present total_pages' do
      subject[:total_pages].should_not be_nil
    end

    it 'should present total_entries' do
      subject[:total_entries].should_not be_nil
    end

    it 'should present collection' do
      subject[:collection].should_not be_nil
    end
  end
end
