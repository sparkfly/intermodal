require 'spec/support/app/db/authentication_schema_helper'

module SpecHelpers
  class Schema
    include Intermodal::Let
    include AuthenticationSchema

    let(:db_migrate) { auth_db_migrate; create_items }
    let(:test_models) { [item_model] }

    let(:create_items) do
      create_table :items do |t|
        t.string  :name
        t.integer :account_id
      end
    end

    let(:item_model) do
      define_model_class :Item do
        include Intermodal::Models::Accountability
      end
    end

    def initialize(_database_type)
      _database_type = _database_type
      self.singleton_class.let(:database_type) { _database_type }
    end

    def up!
      # Drop and recreate database and schema
      db_recreate

      # Load Intermodal account models to top-level objects
      shims

      # Load models for testing Intermodal
      test_models

      establish_redis_connection
    end
  end
end
