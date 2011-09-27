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
  end
end

