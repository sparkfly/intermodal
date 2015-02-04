module Intermodal
  module RSpec
    module Acceptors
      extend ActiveSupport::Concern
      included do
        extend ::Intermodal::RSpec::Macros::Acceptors

        let(:resource_name) { subject.name.underscore }
        let(:acceptor) { api.acceptors[resource_name.to_sym] }
        let(:random_field_data) { "Accepted Field #{rand(100000)}" }

        def acceptance_for(input)
          acceptor.call(input.with_indifferent_access)
        end

        def expects_acceptance(input, expectation)
          acceptance_for(input).should eql(expectation)
        end

        def expects_rejection(input, expectation)
          acceptance_for(input).should_not eql(expectation)
        end
      end
    end

    module Macros
      module Acceptors
        def concerned_with_acceptance(_model, &blk)
          describe _model do
            context "when concerned with acceptance" do
              subject { _model }
              instance_eval(&blk) if blk
            end
          end
        end

        def imposes(*fields)
          fields.each do |field|
            it "should accept #{field}" do
              expects_acceptance({ field => random_field_data }, { field.to_sym => random_field_data })
            end
          end
        end

        def rejects(*fields)
          fields.each do |field|
            it "should reject #{field}" do
              expects_rejection({ field => random_field_data }, { field.to_sym => random_field_data })
            end
          end
        end

        def imposes_named_resource
          context 'when exposing named resource fields' do
            imposes 'name'
          end
        end

        def imposes_linked_resources(linked_resources_name, options = {})
          _linked_resource_name, _linking_association = linked_resources_name.to_s.singularize, options[:with]
          pending "when exposing linked resources, #{_linked_resource_name}" do
            let(:linked_resource_ids_name) { :"#{_linked_resource_name}_ids" }
            let(:linking_association) { :"#{_linking_association}" }
            let(:linked_resource_ids) { subject.send(linking_association).send("to_#{linked_resource_ids_name}") }

            it { should accept "#{_linked_resource_name}_ids" }
            it "should accept \"#{_linked_resource_name}_ids\" as a collection of ids" do
              resource
              (presenter[linked_resource_ids_name].to_a & linked_resource_ids.to_a).should be_empty
            end

            pending "should only accept \"#{_linked_resource_name}_ids\" scoped to account"
          end
        end

      end
    end
  end
end
