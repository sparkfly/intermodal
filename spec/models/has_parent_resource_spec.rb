require 'spec_helper'

describe Intermodal::Models::HasParentResource do
  context 'when implemented as a resource' do
    include SpecHelpers::Application
    include Intermodal::RSpec::HasParentResource

    subject { part }
    let(:parent_resource_name) { :item }
    let(:different_parent) { Item.make!(:account => account) }
    let(:parent_with_different_account) { Item.make!(:account => different_account) }
    let(:different_account) { Account.make! }

    implements_get_interface_for_nested_resource

    pending 'should belong to parent model'
  end
end
