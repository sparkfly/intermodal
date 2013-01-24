module Intermodal
  module RSpec
    # All Intermodal nested resource controllers require models that
    # belongs to an parent object that belongs to an account. It should
    # also respond to #get and verify authorization for the account.
    #
    # This RSpec macro tests these assumptions.
    #
    # Usage:
    #
    # class ParentResource < ActiveRecord::Base
    #   include Intermodal::Models::Accountability
    # end
    #
    # class NestedResource < ActiveRecord::Base
    #   include Intermodal::Models::HasParentResources
    #
    #   parent_resource :parent_resource
    # end
    #
    # describe NestedResource do
    #   include Intermodal::RSpec::HasParentResource
    #
    #   concerned_with_parent_resource :parent_resource
    # end
    #
    # It works with Remarkable. It might work with Shoulda
    #
    # If you don't want to use either, you can pass:
    #
    # describe NestedResource do
    #   include Intermodal::RSpec::HasParentResource
    #
    #   let(:parent_resource_name) { :parent_resource }
    #   let(:different_parent) { ParentResource.make!(:account => account) }
    #   let(:parent_with_different_account) { ParentResource.make!(:account => different_account) }
    #   let(:different_account) { Account.make! }
    #
    #   implements_get_interface_for_nested_resource
    # end
    #
    module HasParentResource
      extend ActiveSupport::Concern

      included do
        include Intermodal::RSpec::Accountability
      end

      module ClassMethods

        # NOTE: I am cheating. It assumes if the class method is defined then
        # it is a scope
        def should_respond_to_scope(scope_method)
          it "should have scope #{scope_method}" do
            subject.class.should respond_to(scope_method)
          end
        end

        def concerned_with_parent_resource(_parent_resource_name, options = {}, &blk)
          extra_get_examples = options[:extra_get_examples]

          context "when concerned with parent resource #{_parent_resource_name}" do
            let(:parent_resource_name) { _parent_resource_name }
            let(:parent_id_name) { "#{parent_resource_name}_id" }
            let(:parent_model) { parent_resource_name.to_s.camelize.constantize }
            let(:different_parent) { parent_model.make! }
            let(:parent_with_different_account) { parent_model.make!(:account => different_account) }

            instance_eval(&blk) if blk

            it { should belong_to _parent_resource_name } unless options[:skip_association_examples]
            # it { should validate_presence_of _parent_resource_name } unless options[:skip_validation_examples]

            [ :by_parent_id, :by_parent, "by_#{_parent_resource_name}_id", "by_#{_parent_resource_name}" ].each do |scope|
              should_respond_to_scope(scope)
            end

            implements_get_interface_for_nested_resource(&extra_get_examples)
          end
        end

        def implements_get_interface_for_nested_resource(&blk)
          implements_get_interface do

            context 'by parent' do
              it 'should find resource scoped to parent' do
                model.get(subject.id, :parent => subject.send(parent_resource_name)).should eql(subject)
              end

              it 'should find resource scoped to parent id' do
                model.get(subject.id, :parent_id => subject.send(parent_resource_name).id).should eql(subject)
              end

              it 'should find writeable resource scoped to parent id' do
                model.get(subject.id, :parent_id => subject.send(parent_resource_name).id).should_not be_readonly
              end
            end

            context 'by parent and account' do
              it 'should find resource scoped to account id and parent id' do
                model.get(subject.id, :parent_id => subject.send(parent_resource_name).id, :account_id => account.id).should eql(subject)
              end

              it 'should find writeable resource scoped to account id and parent id' do
                model.get(subject.id, :parent_id => subject.send(parent_resource_name).id, :account_id => account.id).should_not be_readonly
              end

              it 'should not find resource scoped to a different parent' do
                lambda { model.get(subject.id, :parent => different_parent) }.should raise_error(ActiveRecord::RecordNotFound)
              end

              it 'should not find resource scoped to a different parent id' do
                lambda { model.get(subject.id, :parent_id => different_parent.id) }.should raise_error(ActiveRecord::RecordNotFound)
              end

              it 'should not find resource scoped to a parent in a different account' do
                lambda { model.get(subject.id, :parent_id => parent_with_different_account.id, :account_id => account) }.should raise_error(ActiveRecord::RecordNotFound)
              end

              it 'should not find resource scoped to a correct parent but incorrect account' do
                lambda { model.get(subject.id, :parent_id => subject.send(parent_resource_name).id, :account_id => different_account) }.should raise_error(ActiveRecord::RecordNotFound)
              end
            end

            instance_eval(&blk) if blk
          end
        end # implements_get_interface_for_nested_resource
      end
    end
  end
end

