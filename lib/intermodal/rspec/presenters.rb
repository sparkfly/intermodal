module Intermodal
  module RSpec
    module Presenters
      extend ActiveSupport::Concern
      included do
        extend ::Intermodal::RSpec::Macros::Presenters

        let(:resource) { model.make! }
        let(:resource_name) { model.name.demodulize.underscore }
        let(:presenter) { api.presenter_for(model) }
        let(:presentation) { presenter.call(resource, :scope => scope).with_indifferent_access }
        let(:scope) { :default }

        def expects_presentation(input, expectation)
          field = input.keys[0]
          presenter.call(input.with_indifferent_access, :scope => scope)[field].should eql(expectation)
        end
      end
    end

    module Macros
      module Presenters
        def concerned_with_presentation(_model, &blk)
          describe _model do
            let(:model) { _model }
            subject { model }

            context "when concerned with presentation" do
              instance_eval(&blk) if blk
            end
          end
        end

        def scoped_to(_scope, &blk)
          context "when scoped to #{_scope}" do
            let(:scope) { _scope }
            instance_eval(&blk) if blk
          end
        end

        def exposes(*fields)
          fields.each do |field|
            it "should present #{field}" do
              presentation.should contain(field)
            end
          end
        end

        def hides(*fields)
          fields.each do |field|
            it "should not present #{field}" do
              presentation.should_not contain(field)
            end
          end
        end

        def exposes_resource
          context 'when exposing resource fields' do
            exposes 'id', 'created_at', 'updated_at'
          end
        end

        def exposes_named_resource
          context 'when exposing named resource fields' do
            exposes_resource
            exposes 'name'
          end
        end

        def exposes_linked_resources(linked_resources_name, options = {})
          _linked_resource_name, _linking_association = linked_resources_name.to_s.singularize, options[:with]
          context "when exposing linked resources, #{_linked_resource_name}" do
            let(:linked_resource_ids_name) { :"#{_linked_resource_name}_ids" }
            let(:linking_association) { :"#{_linking_association}" }
            let(:linked_resource_ids) { resource.send(linking_association).send("to_#{linked_resource_ids_name}").to_a }
            let(:presented_linked_ids) { presentation[linked_resource_ids_name].to_a }

            exposes "#{_linked_resource_name}_ids" 
            it "should present \"#{_linked_resource_name}_ids\" as a collection of ids" do
              resource
              (presented_linked_ids - linked_resource_ids).should be_empty
              (linked_resource_ids - presented_linked_ids).should be_empty
            end

            pending "should only present \"#{_linked_resource_name}_ids\" scoped to account"
          end
        end

      end
    end
  end
end
