module Intermodal
  module Mapping
    class Mapper
      class_attribute :_exclude_properties, :_property_mappings, :_mapping_strategy, :api

      INCLUDE_NILS = lambda { |h, resource, mapped_from, mapped_to| h[mapped_from] = map_attribute(resource, mapped_to) }
      EXCLUDE_NILS = lambda { |h, resource, mapped_from, mapped_to| a = map_attribute(resource, mapped_to); h[mapped_from] = a if a }

      class << self
        # :public: Blacklists properties
        def exclude_properties(*args)
          (self._exclude_properties ||= []).push *(args.map(&:to_s))
        end

        # :api: Mapper should respond to .call()
        def call(resource, options = {})
          map_attributes(resource, options[:scope] || :default)
        end

        def property_mapping(scope = :default)
          self._property_mappings ||= {}
          self._property_mappings[scope] ||= []
        end

        # Examples:
        #
        #  maps :name
        #  maps :name, :with => lambda { |o| o.name.camelize }
        #  maps :name, :with => [ :first_name, :last_name, :suffix, :prefix ]
        #  maps :name, :scope => :named
        #
        def maps(property, opts = {})
          scopes = opts[:scope] || [ :default ]
          scopes = (scopes.is_a?(Array) ? scopes : [ scopes ]) 
          scopes.each do |scope|
            # DEPRECATION: option :as
            remapped_property = opts[:with] || opts[:as] || property
            property_mapping(scope).push [property, remapped_property]
          end
        end

        def map_attributes(resource, scope = :default)
          (self._property_mappings[:default] + self._property_mappings[scope]).inject({}) { |m, p|
            m.tap { |h| self._mapping_strategy[h, resource, p[0], p[1]] }
          }.except(*self._exclude_properties)
        end

        def map_attribute(resource, mapped_to)
          case mapped_to
          when Symbol then resource[mapped_to]
          when Proc then
            if mapped_to.arity == 1
              mapped_to.call(resource)
            else
              mapped_to.call()
            end
          when Array then mapped_to.inject({}) { |m, _element| m.tap { |_m| _m[_element] = map_attribute(resource, _element) } }
          end
        end

      end
    end

  end
end
