# Taken from Remarkable 4.0.0 alpha
# https://github.com/remarkable/remarkable/blob/1e653044dfb9726034f600bae13d81e9986c44f6/remarkable_activerecord/spec/support/model_builder.rb

require 'machinist/active_record'

module SpecHelpers
  module ClassBuilder
    extend ActiveSupport::Concern

    def unload_class(class_name)
      Object.send(:remove_const, class_name) if Object.const_defined?(class_name)
    end

    def define_class(class_name, base, &block)
      class_name = class_name.to_s.camelize

      unload_class(class_name)

      Class.new(base).tap do |klass|
        Object.const_set(class_name, klass)
        klass.class_eval(&block) if block_given?
      end
    end

    def define_model_class(class_name, base = nil, &block)
      base = base || ActiveRecord::Base
      klass = define_class(class_name, base) do
        extend Machinist::Machinable
        #include Machinist::Blueprints
        #include Machinist::ActiveRecordExtensions

        def self.blueprint_class
          Machinist::ActiveRecord::Blueprint
        end
      end

      klass.class_eval(&block) if block_given?
      klass
    end 
  end
end
