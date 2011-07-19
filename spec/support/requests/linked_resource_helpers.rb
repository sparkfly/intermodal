module SpecHelpers
  module LinkedResources
    extend ActiveSupport::Concern

    included do
      include SpecHelpers::Resources
      extend  SpecHelpers::Macros::LinkedResources
    end
  end

  module Macros
    module LinkedResources

      def link_resource(parent_resource, options = {}, &blk)
        metadata[:parent_resource] = options[:parent_resource] = parent_resource
        metadata[:target_resources] = options[:to]
        metadata[:linking_resource_model] = options[:with]
        resource_options = {
          :namespace => options[:namespace]
        }
        resources [metadata[:parent_resource].to_s.pluralize, metadata[:target_resources]], resource_options do
          let(:model) { options[:with] }
          let(:model_parents) { [ send(options[:parent_resource]) ] }
          let(:unlinked_targets) { raise "Override :unlinked_targets with let()" }
          instance_eval(&blk)
        end
      end

      def expects_crud_for_linked_resource
        expects_index
        expects_list_replace 
        expects_list_append
        expects_list_remove 
      end

      def expects_list_replace(&blk)
        _metadata = metadata
        request :post, metadata[:collection_url] do
          instance_eval(&blk) if blk
          let(:request_url) { collection_url }
          let(:replacement_target_ids) { unlinked_targets.map(&:id) }
          let(:request_payload) { { _metadata[:target_resources] => replacement_target_ids } }
          let(:updated_target_ids) { model.by_parent(model_parent).to_target_ids }

          expects_status(201)
          expects_content_type(metadata[:mime_type], metadata[:encoding])

          it "should link #{metadata[:target_resources]} to #{metadata[:parent_resource]}" do
            model_collection.should_not be_empty
            response.should_not be_empty
            replacement_target_ids.each do |replacement_target_id|
              updated_target_ids.should include(replacement_target_id)
            end
          end

          it "should delete original linked #{metadata[:target_resources]}" do
            model_collection.should_not be_empty
            response.should_not be_empty
            model_collection.each do |original_target_id|
              updated_target_ids.should_not include(original_target_id)
            end
          end
        end
      end

      def expects_list_append(&blk)
        _metadata = metadata
        request :put, metadata[:collection_url] do
          instance_eval(&blk) if blk
          let(:request_url) { collection_url }
          let(:additional_target_ids) { unlinked_targets.map(&:id) }
          let(:request_payload) { { _metadata[:target_resources] => additional_target_ids } }
          let(:updated_target_ids) { model.by_parent(model_parent).to_target_ids }

          expects_status(200)
          expects_content_type(metadata[:mime_type], metadata[:encoding])

          it 'should link additional targets to manufacturer' do
            model_collection.should_not be_empty
            response.should_not be_empty
            additional_target_ids.each do |additional_target_id|
              updated_target_ids.should include(additional_target_id)
            end
          end

          it 'should append to, but not delete original linked targets' do
            model_collection.should_not be_empty
            response.should_not be_empty
            model_collection.each do |original_target_id|
              updated_target_ids.should include(original_target_id)
            end
          end
        end
      end

      def expects_list_remove(&blk)
        _metadata = metadata
        request :delete, metadata[:collection_url] do
          instance_eval(&blk) if blk
          let(:request_url) { collection_url }
          let(:deleted_target_ids) { model_collection[0..1] }
          let(:remaining_target_ids) { model_collection - deleted_target_ids }
          let(:request_payload) { { _metadata[:target_resources] => deleted_target_ids } }
          let(:updated_target_ids) { model.by_parent(model_parent).to_target_ids }

          expects_status(200)
          expects_content_type(metadata[:mime_type], metadata[:encoding])

          it 'should delete linked targets' do
            deleted_target_ids.should_not be_empty
            response.should_not be_empty
            deleted_target_ids.each do |deleted_target_id|
              updated_target_ids.should_not include(deleted_target_id)
            end
          end

          it 'should keep remaining targets' do
            deleted_target_ids.should_not be_empty
            response.should_not be_empty
            remaining_target_ids.each do |remaining_target_id|
              updated_target_ids.should include(remaining_target_id)
            end
          end
        end
      end

    end
  end
end
