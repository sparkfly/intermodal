module SpecHelpers
  module AuthenticationSchema
    extend ActiveSupport::Concern

    included do
      include SpecHelpers::Adapter
      include SpecHelpers::Migration
      include SpecHelpers::ClassBuilder
      include SpecHelpers::Blueprints
      
      # Convenience methods
      let(:account) { Account.make! }
      let(:access_credential) { AccessCredential.make!(:account => account) }
      let(:access_token) { AccessToken.generate!(account) }
      
      # Simulates rake db:migrate
      let(:db_migrate) { create_accounts; create_account_credentials }

      # Simulates rake db:recreate
      let(:db_recreate) { recreate_database; db_migrate }

      # Schema Migrations
      let(:create_accounts) do
        create_table :accounts do |t|
          t.string :name
        end
      end

      # Note: Properly, account_id should be a foreign key reference
      # but this is not important for the purpose of testing Intermodal
      let(:create_account_credentials) do
        create_table :access_credentials do |t|
          t.integer :account_id
          t.string  :identity
          t.string  :key
        end
      end

      let(:start_redis) { AccessToken.establish_connection! }

      # Shims
      let(:shims) { [shim_for_account, shim_for_access_credential, shim_for_access_token] }

      let(:shim_for_account) do
        define_model_class :Account do
          include Intermodal::Models::Account
        end
      end

      let(:shim_for_access_credential) do
        define_model_class :AccessCredential do
          include Intermodal::Models::AccessCredential
        end
      end

      let(:shim_for_access_token) do
        define_class :AccessToken, Object do
          include Intermodal::Models::AccessToken
        end
      end
    end

    module ClassMethods
      def use_authentication_schema(db_type = nil)
        _db_type = db_type || :postgresql
        let(:database_type) { _db_type }


        # TODO:
        # Somehow, using let() to recreate a postgresql database using a
        # before(:all) hook makes let() not work. In this current setup,
        # the first let(:http_headers) wins out, thus making the spec fail.
        # It does not matter what you use, all let() declarations gets
        # memoized.
        #
        # Postgresql *will* work if we use before(:each) to recreate the
        # database. But it is also slow.
        #
        # I tried using sqlite3 in-memory instead. I get errors with 
        # ActiveRecord model unable to find the table.
        #
        # I'm using before(:each) on Postgresql for now, until I fix these
        # other problems. Ideally, I can freely use both, recreating the
        # database only at the top of the example group.
        
        before(:each)  { db_recreate; shims; start_redis; blueprints }
        before(:each) { DatabaseCleaner.start }
        after(:each)  { DatabaseCleaner.clean }
      end
    end
  end
end
