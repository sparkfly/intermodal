require 'spec_helper'

describe Intermodal::Mapping::Acceptor do
  include SpecHelpers::ClassBuilder

  describe '.call' do
    subject { acceptor.call(params) }

    context 'with pass-through mappings' do
      let(:acceptor) do
        define_class :TestAcceptor, Intermodal::Mapping::Acceptor do
          accepts :acceptable_field
          accepts :optional_field
        end
      end

      let(:value) { 'Accepted Field' }
      let(:params) { { :acceptable_field => value, :unacceptable_field => true } }

      it 'should accept explicitly whitelisted fields' do
        should include(:acceptable_field)
      end

      it 'should pass through value without transformation' do
        subject[:acceptable_field].should eql(value)
      end

      it 'should not accept undeclared fields' do
        should_not include(:unacceptable_field)
      end

      context 'without optional field in params' do
        # Since we pass the output of an acceptor directly into
        # the active record #create or #update_attributes, we want
        # the hash to look like:
        #
        # { :acceptable_fields => 'Something' }
        #
        # rather than
        #
        # { :acceptable_field => 'Something', :optional_field => nil }
        #
        # Doing so will update the resource and null out the fields that
        # have not been passed through params.
        it 'should not include the optional field' do
          should_not include(:optional_field)
        end
      end

      context 'with optional field in params' do
        let(:params) { { :acceptable_field => value, :optional_field => value } }

        it 'should include the optional field' do
          should include(:optional_field)
        end

        it 'should pass through value without transformation' do
          subject[:optional_field].should eql(value)
        end
      end
    end

    pending 'with scoped acceptor'
  end
end

