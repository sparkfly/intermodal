require 'spec/support/app/db/authentication_schema_helper'

module SpecHelpers
  class Schema
    include Intermodal::Let
    include AuthenticationSchema

    def initialize(_database_type)
      _database_type = _database_type
      self.singleton_class.let(:database_type) { _database_type }
    end

    def up!
      # Drop and recreate database and schema
      db_recreate

      # Load Intermodal account models to top-level objects
      shims

      establish_redis_connection
    end
  end
end
