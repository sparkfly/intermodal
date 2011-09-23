require 'spec_helper'

describe Intermodal::Models::Accountability do
  context 'when implemented as a resource' do
    include SpecHelpers::Application
    include Intermodal::RSpec::Accountability

    subject { item }
    implements_get_interface

    pending 'should belong to account model'
  end
end
