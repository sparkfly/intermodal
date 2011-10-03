require 'spec_helper'

describe Intermodal::Models::ResourceLinking do
  context 'when implemented as a resource' do
    include SpecHelpers::Application
    include Intermodal::RSpec::ResourceLinking

    subject { sku }

    let(:model) { Sku }
    let(:skus) { item.vendors << vendors }

    # Protip: sku, item, and vendors can be defined in a global helper, such as SpecHelpers::Application
    let(:sku) { Sku.create(:item => item, :vendor => vendor) }
    let(:item) { Item.make!(:account => account) }
    let(:vendor) { Vendor.make!(:account => account) }
    let(:vendors) { (1..3).map { Vendor.make!(:account => account) } }

    concerned_with_resource_linking :item, :vendor, :skip_association_examples => true, :skip_validation_examples => true
  end
end
