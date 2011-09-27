require 'spec_helper'

describe Intermodal::Mapping::Acceptor do
  include SpecHelpers::ClassBuilder

  subject { acceptor.call(params) }

  let(:acceptor) do
    define_class :TestAcceptor, Intermodal::Mapping::Acceptor do
      accepts :acceptable_field
    end
  end

  let(:value) { 'Accepted Field' }
  let(:params) { { :acceptable_field => value, :unacceptable_field => true } }

  it 'should accept explicitly whitelisted fields' do
    should include(:acceptable_field)
  end

end

