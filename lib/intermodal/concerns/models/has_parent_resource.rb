module Intermodal
  module Models
    module HasParentResource
      extend ActiveSupport::Concern

      included do
        include Intermodal::Models::Presentation
      end

      module ClassMethods
        include Models::Accountability::Get

        def parent_resource(resource, options = {})
          parent_resource_scope = "by_#{resource}_id"
          parent_table_name = options[:parent_table_name] || resource.to_s.pluralize

          instance_eval do
            if options[:class_name]
              belongs_to resource, :class_name => options[:class_name]
            else
              belongs_to resource
            end

            # validates_presence_of resource

            scope parent_resource_scope, lambda { |id| where("#{resource}_id" => id) }
            scope "by_#{resource}", lambda { |parent| send(parent_resource_scope, parent.id) }
            scope "by_parent_id", lambda { |id| send(parent_resource_scope, id) }
            scope :by_parent, lambda { |parent| by_parent_id(parent.id) }

            scope :by_account_id, lambda { |a_id| joins(resource).where( parent_table_name => { :account_id => a_id } ) }
            scope :by_account, lambda { |a| by_account_id(a.id) }
          end
        end

        def build_get_query(_query, opts)
          _query = super(_query, opts)
          _query = _query.by_parent(opts[:parent]) if opts[:parent]
          _query = _query.by_parent_id(opts[:parent_id]) if opts[:parent_id]
          return _query
        end
      end
    end
  end
end
