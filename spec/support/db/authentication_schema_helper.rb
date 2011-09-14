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

      # Shims
      let(:shims) { [shim_for_account, shim_for_access_credential, shim_for_access_token] }
      let(:shim_for_account)           { define_model_class :Account, Intermodal::Models::Account }
      let(:shim_for_access_credential) { define_model_class :AccessCredential, Intermodal::Models::AccessToken }
      let(:shim_for_access_token)      { define_model_class :AccessToken, Intermodal::Models::AccessToken }
    end

    module ClassMethods
      def use_authentication_schema(db_type = nil)
        _db_type = db_type || :postgresql
        let(:database_type) { _db_type }

        before(:all)  { db_recreate; shims; blueprints }
        before(:each) { DatabaseCleaner.start }
        after(:each)  { DatabaseCleaner.clean }
      end
    end
  end
end
