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
    before(:each) { api_class.load_presentations! }
    subject { presented_collection }

    let(:presenter) { api_class.presenters[:item] }
    let(:collection) { Item.make!(3, :account => account) }
    let(:paginated_collection) { collection; Item.paginate :page => 1 }
    let(:presented_collection) { paginated_collection.as_json presenter_options }

    let(:collection_ids) { collection.map(&:id) }

    let(:_ids) { ->(r) { r[:id] } }
    let(:presented_collection_ids) { presented_collection[:collection].map(&_ids) }

    context 'with presenter default options' do
      let(:presenter_options) { { :presenter => presenter } }

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

      it 'should present collection of resources' do
        presented_collection_ids.should eql(collection_ids)
      end
    end

    context 'with root option' do
      let(:presenter_options) { { :presenter => presenter, :root => root } }
      let(:root) { :node }
      let(:presented_collection_ids) { presented_collection[root].map(&_ids) }

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
        subject[root].should_not be_nil
      end

      it 'should present collection of resources' do
        presented_collection_ids.should eql(collection_ids)
      end
    end

    context 'with always_nest_collections option' do
      let(:presenter_options) { { :presenter => presenter, :always_nest_collections => true } }
      let(:presented_collection_ids) { presented_collection[:collection].map(&_ids) }
      let(:_ids) { ->(r) { r['item'][:id] } }

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

      it 'should present collection of resources' do
        presented_collection_ids.should eql(collection_ids)
      end
    end

    context 'with always_nest_collections and root option' do
      let(:presenter_options) { { :presenter => presenter, :root => root, :always_nest_collections => true } }
      let(:root) { :nodes }
      let(:element_name) { root.to_s.singularize }
      let(:presented_collection_ids) { presented_collection[root].map(&_ids) }
      let(:_ids) { ->(r) { r[element_name][:id] } }

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
        subject[root].should_not be_nil
      end

      it 'should present collection of resources' do
        presented_collection_ids.should eql(collection_ids)
      end
    end
  end
end
