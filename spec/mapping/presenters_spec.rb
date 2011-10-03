require 'spec_helper'

describe Intermodal::Mapping::Presenter do
  include SpecHelpers::ClassBuilder
  include SpecHelpers::Application

  describe '.call' do
    subject { presenter.call(resource) }
    let(:resource) { item }

    context 'with pass-through mappings' do
      let(:presenter) do
        define_class :TestPresenter, Intermodal::Mapping::Presenter do
          presents :name
          presents :description
        end
      end

      it 'should present explicitly whitelisted fields' do
        should include(:name)
      end

      it 'should pass through value without transformation' do
        subject[:name].should eql(resource.name)
      end

      it 'should present all declared fields regardless of value' do
        should include(:description)
        subject[:description].should be_nil
      end
    end

    context 'with pass-through alias mappings' do
      let(:presenter) do
        define_class :TestPresenter, Intermodal::Mapping::Presenter do
          presents :full_name, :with => :name
        end
      end

      it 'should present explicitly whitelisted fields' do
        should include(:full_name)
      end

      it 'should pass through value without transformation' do
        subject[:full_name].should eql(resource.name)
      end

      it 'should not present undeclared fields' do
        should_not include(:name)
      end
    end

    context 'with nested mappings' do
      let(:presenter) do
        define_class :TestPresenter, Intermodal::Mapping::Presenter do

          # Use this to create nested presentation
          presents :metadata, :with => [ :name, :description ]
        end
      end

      let(:resource) { Item.make(:name => name, :description => description) }
      let(:name) { 'Weird Eureka Thing' }
      let(:description) { 'Makes Eureka Go Boom!' }

      it 'should merge fields into a single hash of fields' do
        should include(:metadata)
        subject[:metadata].should include(:name)
        subject[:metadata].should include(:description)
      end

      it 'should merge fields without transforming its value' do
        subject[:metadata][:name].should eql(name)
        subject[:metadata][:description].should eql(description)
      end

      # Unless you've explicitly declared the merged fields, it should
      # not present it.
      it 'should not present undeclared fields' do
        should_not include(:name)
        should_not include(:description)
      end
    end

    context 'with arbitrary mappings' do
      let(:presenter) do
        define_class :TestPresenter, Intermodal::Mapping::Presenter do
          # This lets you use aribrary functions to map out accepted fields.
          # Beware! For many use-cases, declaring these in the model works better.
          # Beware! Do not use functions with side-effects
          presents :name, :with => lambda { |o| o[:name].upcase }
        end
      end

      it 'should accept an arbitrary mapping' do
        should include(:name)
      end

      it 'should transform the value' do
        subject[:name].should_not eql(resource.name)
      end
    end

    context 'when scoping' do
      subject { presenter.call(resource, :scope => scope) }

      context 'without scope declaration' do
        let(:scope) { :default }
        let(:presenter) do
          define_class :TestPresenter, Intermodal::Mapping::Presenter do
            presents :name
          end
        end

        it 'should default to :default scope' do
          should include(:name)
          subject[:name].should eql(resource.name)
        end
      end

      context 'with mixed scopes' do
        let(:scope) { :default }
        let(:presenter) do
          define_class :TestPresenter, Intermodal::Mapping::Presenter do
            presents :name
            presents :description, :scope => :details
          end
        end

        let(:resource) { Item.make(:name => name, :description => description) }
        let(:name) { 'Weird Eureka Thing' }
        let(:description) { 'Makes Eureka Go Boom!' }

        it 'should default to :default scope' do
          should include(:name)
          subject[:name].should eql(resource.name)
        end

        it 'should not present attributes outside of scope' do
          should_not include(:description)
        end

        context 'when called with non-default scope' do
          let(:scope) { :details }

          it 'should include non-overlapping attributes from default scope' do
            should include(:name)
            subject[:name].should eql(resource.name)
          end

          it 'should present attributes from non-default scope' do
            should include(:description)
            subject[:description].should eql(resource.description)
          end
        end
      end

      context 'with overlapping scopes' do
        let(:scope) { :default }
        let(:presenter) do
          define_class :TestPresenter, Intermodal::Mapping::Presenter do
            presents :name
            presents :name, :with => lambda { |o| 'boo!' }, :scope => :details
          end
        end

        it 'should default to :default scope' do
          should include(:name)
          subject[:name].should eql(resource.name)
        end

        context 'when called with non-default scope' do
          let(:scope) { :details }

          it 'should present attributes from non-default scope' do
            should include(:name)
            subject[:name].should_not eql(resource.name)
            subject[:name].should eql('boo!')
          end
        end
      end
    end
  end
end

