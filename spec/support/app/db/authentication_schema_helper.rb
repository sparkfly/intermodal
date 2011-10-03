require 'spec/support/app/db/adapter_helper'
require 'spec/support/app/db/migration_helper'
require 'spec/support/app/class_builder'

module SpecHelpers
  module AuthenticationSchema
    extend ActiveSupport::Concern

    included do
      include SpecHelpers::Adapter
      include SpecHelpers::Migration
      include SpecHelpers::ClassBuilder

      # Simulates rake db:migrate
      let(:auth_db_migrate) { create_accounts; create_account_credentials }
      let(:db_migrate) { auth_db_migrate }

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

      let(:establish_redis_connection) { AccessToken.establish_connection! }

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
  end
end
