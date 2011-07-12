module Intermodal
  module Models
    module ResourceLinking
      extend ActiveSupport::Concern

      included do
        include Intermodal::Models::HasParentResource
        extend ClassMethods
      end

      module ClassMethods
        include HasParentResource::ClassMethods

        def links_resource(_parent, options = {})
          raise "Must supply :to" unless options[:to]

          _target_resource = options[:to]
          _target_resource_class_name = options[:class_name]
          _target_table_name = options[:target_table_name] || _target_resource.to_s.pluralize
          _parent_resource_class_name = options[:parent_class_name]
          _parent_table_name = options[:parent_table_name] || _parent.to_s.pluralize

          instance_eval do
            parent_resource(_parent, :class_name => _parent_resource_class_name)

            # Associations
            if _target_resource_class_name
              belongs_to _target_resource, :class_name => _target_resource_class_name
            else
              belongs_to _target_resource
            end

            # Scopes
            scope "by_#{_target_resource}_id", lambda { |_id| where("#{target_resource_name}_id" => _id) }
            scope :by_target_id, lambda { |_id| send("by_#{target_resource_name}_id", _id) }
            #scope :by_target_account_id, lambda { |a_id| 
            #    joins(_target_resource).
            #    where(_target_table_name => { :account_id => a_id })}
            #scope :by_target_account, lambda { |a| by_target_account_id(a.id) }
            #scope :_by_target_account_id, lambda { |a_id| where(_target_table_name => { :account_id => a_id})}

            # Transformations
            def self.to_target_ids
              select("#{target_resource_name}_id").map(&"#{target_resource_name}_id".to_sym)
            end

            # Links parent resource and target resource
            class_inheritable_accessor :target_resource_name, :target_resource_class_name, :parent_resource_name, :parent_resource_class_name

            def self.parent_model
              (parent_resource_class_name || parent_resource_name.to_s.camelize).constantize
            end

            def self.target_model
              (target_resource_class_name || target_resource_name.to_s.camelize).constantize
            end

            singleton_class.instance_eval do
              define_method "to_#{_target_resource}_ids" do
                to_target_ids
              end
            end
          end

          # Set class inheritable variables
          self.target_resource_name = _target_resource
          self.target_resource_class_name = _target_resource_class_name
          self.parent_resource_name = _parent
          self.parent_resource_class_name = _parent_resource_class_name
        end

        def build_get_query(_query, opts)
          _query = super(_query, opts)
          #_query.build_arel
          #_query = _query.by_target_account(opts[:account]) if opts[:account]
          #_query = _query.by_target_account_id(opts[:account_id]) if opts[:account_id]
          # HACK:
          # Workaround for Arel bug
          #_query = _query._by_target_account_id(opts[:account_id]) if opts[:account_id]
          return _query
        end

        # Standard Methods for all linking resources

        # .replace
        #  - replaces existing resources with new resource ids
        #  - existing resources gets deleted
        def replace(parent_id, resource_ids, options = {})
          transaction do
            parent = parent_model.get(parent_id, options.except(:parent, :parent_id))
            return nil unless parent

            targets = target_model.get(:all, options).where(:id => resource_ids)
            parent.send("#{target_resource_name.to_s.pluralize}=", targets)
            by_parent_id(parent_id).to_target_ids
          end
        end

        # .append
        #  - adds new resources into the list
        #  - does not add redundent resources
        def append(parent_id, resource_ids, options = {})
          transaction do
            parent = parent_model.get(parent_id, options.except(:parent, :parent_id))
            return nil unless parent

            resource_ids = resource_ids - by_parent_id(parent_id).by_target_id(resource_ids).to_target_ids
            parent.send("#{target_resource_name.to_s.pluralize}") << target_model.get(:all, options).where(:id => resource_ids)
          end
        end

        # .remove
        #  - removes specified lists
        def remove(parent_id, resource_ids, options = {})
          transaction do
            parent = parent_model.get(parent_id, options.except(:parent, :parent_id))
            return nil unless parent

            by_parent_id(parent_id).by_target_id(resource_ids).delete_all
            by_parent_id(parent_id).to_target_ids
          end
        end
      end
    end
  end
end
