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

    context 'with nested mappings' do
      let(:acceptor) do
        define_class :TestAcceptor, Intermodal::Mapping::Acceptor do
          # Use this to create nested parameters from flattened parameters
          accepts :name, :as => [ :first_name, :last_name ]
        end
      end

      let(:first_name) { 'Henry' }
      let(:last_name) { 'Deacon' }
      let(:params) { { :first_name => first_name, :last_name => last_name } }

      it 'should merge fields into a single hash of fields' do
        should include(:name)
        subject[:name].should include(:first_name)
        subject[:name].should include(:last_name)
      end

      it 'should merge fields without transforming its value' do
        subject[:name][:first_name].should eql(first_name)
        subject[:name][:last_name].should  eql(last_name)
      end

      # Unless you've explicitly declared the merged fields, it should
      # not include it.
      it 'should not accept merged fields' do
        should_not include(:first_name)
        should_not include(:last_name)
      end
    end

    context 'with arbitrary mappings' do
      let(:acceptor) do
        define_class :TestAcceptor, Intermodal::Mapping::Acceptor do
          # This lets you use aribrary functions to map out accepted fields.
          # Beware! For many use-cases, declaring these in the model works better.
          # Beware! Do not use functions with side-effects
          accepts :phone_number, :as => lambda { |o| o[:phone_number].gsub(/[^0-9]/, '') }
        end
      end

      let(:value) { '555-555-5555' }
      let(:params) { { :phone_number => value } }

      it 'should accept an arbitrary mapping' do
        should include(:phone_number)
      end

      it 'should transform the value' do
        subject[:phone_number].should_not eql(value)
      end
    end

    pending 'with scoped acceptor'
  end
end

