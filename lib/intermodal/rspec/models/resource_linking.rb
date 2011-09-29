module Intermodal
  module RSpec
    module ResourceLinking
      extend ActiveSupport::Concern

      included do
        include Intermodal::RSpec::HasParentResource
      end

      module ClassMethods
        # To use this, you must define the resources in SpecHelpers::Application
        # This ensures that all the linked resources are scoped to the same account
        #
        # Example:
        #
        # concerned_with_resource_linking :item, :vendor
        #
        # Somewhere within the spec scope, you must define the following:
        #
        # let(:model) { Sku }
        # let(:skus) { item.vendors << vendors }
        # let(:item) { Item.make(:account => account) }
        # let(:vendors) { (1..3).map { Vendor.make(:account => account) }
        # let(:account) { Account.make }
        #
        # Optional:
        #   If you are not running Remarkable or Shoulda, you can pass :skip_association_examples => true
        def concerned_with_resource_linking(_parent_resource_name, _target_resource_name, options = {},  &blk)
          context "when concerned with linking #{_parent_resource_name} to #{_target_resource_name}", options do
            _metadata = metadata

            let(:parent_resource_name) { _parent_resource_name }
            let(:target_resource_name) { _target_resource_name }

            let(:model_name) { model.model_name.demodulize.underscore.to_sym }
            let(:model_association_name) { model_name.to_s.pluralize }
            let(:parent) { send(parent_resource_name) }
            let(:parent_with_different_account) { parent.class.make(:account => different_account) }
            let(:targets) { send(target_resource_name.to_s.pluralize) }
            let(:list) { send(model_association_name) }

            let(:target_association_name) { target_resource_name.to_s.pluralize }
            let(:target_model) { (_metadata[:class_name] || target_resource_name).to_s.camelize.constantize }
            let(:target_model_blueprint) { proc do target_model.make!(:account => account) end }
            let(:target_model_blueprint_with_different_account) { proc do target_model.make!(:account => different_account) end }
            let(:target_accounts) { targets.map(&:account) }
            let(:target_with_different_account) { target_model_blueprint_with_different_account[] }
            let(:targets_with_different_account) { (1..3).map { target_model_blueprint_with_different_account[] } }
            let(:target_ids_with_different_account) { targets_with_different_account.map(&:id) }

            instance_eval(&blk) if blk

            # Examples
            get_examples_for_linked_targets = proc do
              pending 'by target' do
                it 'should find targets scoped to the same account' do
                  target_accounts.each do |target_account|
                    target_account.should eql(parent_account)
                  end
                  model.get(subject.id, :account => parent_account).should eql(subject)
                end
                it 'should not find targets scoped to another account' do
                  parent.send(target_association_name) <<  target_with_different_account
                  model.get(:all, :account => different_account).send("to_#{target_resource}_ids").should_not include(target_with_different_account.id)
                end
                let(:parent_association) {
                  parent.send(target_association_name) <<  target_with_different_account
                  parent.send(target_association_name) }
                  let(:query) { model.get(:all, :account => different_account).to_sql }
                  #debug_examples :target_with_different_account, :parent_association, :account, :different_account, :parent, :query
              end
            end

            concerned_with_parent_resource(_parent_resource_name, { :extra_get_examples => get_examples_for_linked_targets }.merge(options)) do
              let(:parent_model) { parent.class }
              let(:parent_account) { parent.account }
              instance_eval(&options[:extra_parent_resource_examples]) if options[:extra_parent_resource_examples]
            end

            unless options[:skip_association_examples]
              it { should belong_to target_resource_name }
              it { subject.class.should respond_to :by_target_id }
              it { subject.class.should respond_to "by_#{target_resource_name}_id" }
            end

            describe ".to_#{_target_resource_name}_ids" do
              subject { list; parent.send(model_association_name).send("to_#{_target_resource_name}_ids") }

              it "should return a list of #{_target_resource_name} ids" do
                should be_kind_of(Array)
                subject.map do |id|
                  (id + 0).should eql(id)
                end
              end

              it "should return all #{_target_resource_name} ids that linked to the #{_parent_resource_name}" do
                target_model.where(:id => subject).each do |linked_resource|
                  targets.should include(linked_resource)
                end
              end
            end

            describe '.replace' do
              let(:replacement_targets) { (1..3).map(&target_model_blueprint) }
              let(:replacement_target_ids) { replacement_targets.map(&:id) }
              let(:original_target_ids) { list; parent.send(target_association_name).map(&:id) }
              let(:updated_target_ids) { model.get(:all, :parent => parent).to_target_ids }
              subject { list; model.replace(parent.id, replacement_target_ids) }

              it "should link the target ids to the parent #{_parent_resource_name}" do
                original_target_ids.should_not be_empty
                subject.should_not be_empty
                updated_target_ids.sort.should eql(replacement_target_ids.sort)
              end

              context 'when scoped to an account' do
                it 'should link to a parent scoped to the account' do
                  model.replace(parent, replacement_target_ids, :account => account).should_not be_empty
                end

                it 'should not link to a parent scoped to a different account' do
                  model.replace(parent_with_different_account.id, replacement_target_ids, :account => account).should be_nil
                end

                it "should only accept target ids that belong to the same account" do
                  subject.should_not be_empty
                  model.replace(parent.id, target_ids_with_different_account, :account => account).should be_empty
                end

                it 'should only accept target ids that belong to the same account id' do
                  subject.should_not be_empty
                  model.replace(parent.id, target_ids_with_different_account, :account_id => account.id).should be_empty
                end
              end

              it "should delete the existing links to the parent #{_parent_resource_name}" do
                original_target_ids.should_not be_empty
                subject.should_not be_empty
                (original_target_ids & updated_target_ids).should be_empty
              end
            end

            describe '.append' do
              let(:additional_targets) { (1..3).map(&target_model_blueprint) }
              let(:additional_target_ids) { additional_targets.map(&:id) }
              let(:original_target_ids) { list; parent.send(target_association_name).map(&:id) }
              let(:updated_target_ids) { parent.send(target_association_name).map(&:id) }
              subject { list; model.append(parent.id, additional_target_ids) }

              it "should link additional #{_target_resource_name} ids to the parent #{_parent_resource_name}" do
                subject.should_not be_empty
                additional_target_ids do |additional_target_id|
                  updated_target_ids.should include(additional_target_id)
                end
              end

              context 'when scoped to an account' do
                it 'should link to a parent scoped to the account' do
                  model.append(parent, additional_target_ids, :account => account).should_not be_empty
                end

                it 'should not link to a parent scoped to a different account' do
                  model.append(parent_with_different_account.id, additional_target_ids, :account => account).should be_nil
                end

                it "should only accept target ids that belong to the same account" do
                  subject.should_not be_empty
                  model.append(parent.id, target_ids_with_different_account, :account => account).should_not be_empty
                  updated_target_ids.should eql(updated_target_ids - target_ids_with_different_account)
                end

                it 'should only accept target ids that belong to the same account id' do
                  subject.should_not be_empty
                  model.append(parent.id, target_ids_with_different_account, :account_id => account.id).should_not be_empty
                  updated_target_ids.should eql(updated_target_ids - target_ids_with_different_account)
                end
              end

              it "should keep existing links to the parent #{_parent_resource_name}" do
                original_target_ids.should_not be_empty
                subject.should_not be_empty
                original_target_ids do |original_target_id|
                  updated_target_ids.should include(original_target_id)
                end
              end

              it "should not append existing links to the parent #{_parent_resource_name}" do
                2.times { model.append(parent.id, additional_target_ids) }
                additional_target_ids.each do |additional_target_id|
                  model.by_parent(parent).by_target_id(additional_target_id).length.should eql(1)
                end
              end
            end

            describe '.remove' do
              let(:original_target_ids) { list; parent.send(target_association_name).map(&:id) }
              let(:removed_target_ids) { original_target_ids[0..1] }
              let(:remaining_target_ids) { original_target_ids - removed_target_ids }
              let(:updated_target_ids) { parent.send(target_association_name).map(&:id) }
              subject { list; model.remove(parent.id, removed_target_ids) }

              it "should delete the existing links to the parent #{_parent_resource_name}" do
                removed_target_ids.should_not be_empty
                subject.should_not be_empty
                removed_target_ids do |removed_target_id|
                  updated_target_ids.should_not include(removed_target_id)
                end
              end

              context 'when scoped to an account' do
                it 'should link to a parent scoped to the account' do
                  model.remove(parent, removed_target_ids, :account => account).should_not be_empty
                end

                it 'should not unlink from a parent scoped to a different account' do
                  model.remove(parent_with_different_account.id, removed_target_ids, :account => account).should be_nil
                end
              end

              it "should keep remaining links to the parent" do
                removed_target_ids.should_not be_empty
                subject.should_not be_empty
                remaining_target_ids do |original_target_id|
                  updated_target_ids.should include(remaining_target_id)
                end
              end

            end
          end
        end
      end
    end
  end
end
