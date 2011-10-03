module SpecHelpers
  module Adapter
    extend ActiveSupport::Concern

    CONFIGURATIONS = {
      :postgresql => {
        :adapter => "postgresql",
        :username => "postgres",
        :password => "",
        :database => "test",
        :min_messages => "ERROR" },
      :postgresql_admin => {
        :adapter => "postgresql",
        :username => "postgres",
        :password => "",
        :database => "admin",
        :min_messages => "ERROR" }, 
      # :postgresql_admin is used to connect in; :postgresql is used to actually test the migrations
      :mysql => {
        :adapter => 'mysql',
        :host => 'localhost',
        :username => 'root',
        :database => 'test' }, 
      :sqlite3 => {
        :adapter => "sqlite3",
        :database => ":memory:" } }

    included do
      let(:database_env) { CONFIGURATIONS[database_type] }
      let(:database_name) { database_env[:database] }
      let(:postgres_admin_env) { CONFIGURATIONS[:postgresql_admin] }

      let(:recreate_database) do
        if database_type.to_s == 'sqlite3'
          ActiveRecord::Base.establish_connection(database_env)
          next
        end

        ActiveRecord::Base.establish_connection(CONFIGURATIONS[:postgresql_admin]) if database_type.to_s == 'postgresql'

        ActiveRecord::Base.connection.drop_database(database_name)
        ActiveRecord::Base.connection.create_database(database_name)

        if database_type.to_s == 'postgresql'
          ActiveRecord::Base.connection.disconnect!
          ActiveRecord::Base.establish_connection(database_env)
        else
          ActiveRecord::Base.connection.reset!
        end
      end
    end
  end
end
