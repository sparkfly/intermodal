# Adapted from Foreigner migration helper
# See: https://github.com/hosh/foreigner/blob/c46316a5a408b5746fd38acd7015968c29329c21/spec/support/factory_helper.rb
module SpecHelpers
  module Migration

    # Creates a new anonymous migration and puts something into self.up
    # Example:
    #   let(:migration) do
    #     create_migration do
    #       create_table :items do |t|
    #         t.string :name
    #       end
    #     end
    #   end
    def create_migration(&blk)
      migration = Class.new(ActiveRecord::Migration)

      # This is the equivalent of 
      # class Foo
      #   def self.up 
      #   end
      # end

      migration.singleton_class.class_eval do
        define_method(:up, &blk)
      end
      migration
    end

    # Creates a new, anonymous table migration and activates it
    # Example:
    #   let(:create_items) do
    #     create_table :items do |t|
    #       t.string :name
    #     end
    #   end
    def create_table(table = :items, opts = {}, &blk)
      migration = create_migration do
        create_table(table, opts, &blk)
      end
      migration.up 
    end
  end
end
