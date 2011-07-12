module Intermodal
  module Models
    module Accountability
      extend ActiveSupport::Concern

      included do
        include Intermodal::Models::Presentation

        # Validations
        validates_presence_of :account

        # Associations
        belongs_to :account

        # Scopes
        scope :by_account_id, lambda { |a_id| where(:account_id => a_id) }
        scope :by_account, lambda { |a| by_account_id(a.id) }

        # Presentation
        #exclude_from_presentation :account_id

        extend Get
      end

      module Get
        # API: overrideable
        # Use this to extend Get
        def build_get_query(_query, opts)
          _query = _query.by_account(opts[:account]) if opts[:account]
          _query = _query.by_account_id(opts[:account_id]) if opts[:account_id]
          return _query
        end

        def get(_id, opts = {})
          _query = build_get_query(scoped, opts)
          return _query if _id == :all

          # Force false on readonly
          _resource = _query.where(:id => _id).limit(1).readonly(false).first
          return _resource
        end
      end
    end
  end
end
