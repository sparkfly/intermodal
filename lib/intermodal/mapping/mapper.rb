module Intermodal
  module Mapping
    class Mapper
      class_inheritable_accessor :_exclude_properties, :_property_mappings, :_mapping_strategy

      INCLUDE_NILS = lambda { |h, resource, mapped_from, mapped_to| h[mapped_from] = map_attribute(resource, mapped_to) }
      EXCLUDE_NILS = lambda { |h, resource, mapped_from, mapped_to| a = map_attribute(resource, mapped_to); h[mapped_from] = a if a }

      class << self
        def exclude_properties(*args)
          (self._exclude_properties ||= []).push *(args.map(&:to_s))
        end

        def property_mapping(scope = :default)
          self._property_mappings ||= {}
          self._property_mappings[scope] ||= []
        end

        # Examples:
        #
        #  maps :name
        #  maps :name, :as => lambda { |o| o.name.camelize }
        #  maps :name, :as => [ :first_name, :last_name, :suffix, :prefix ]
        #  maps :name, :scope => :named
        #
        def maps(property, opts = {})
          scopes = opts[:scope] || [ :default ]
          scopes = (scopes.is_a?(Array) ? scopes : [ scopes ]) 
          scopes.each do |scope|
            property_mapping(scope).push [property, (opts[:as] ? opts[:as] : property)]
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
          when Proc then mapped_to[resource]
          when Array then mapped_to.inject({}) { |m, _element| m.tap { |_m| _m[_element] = map_attribute(resource, _element) } }
          end
        end

        def call(resource, scope = :default)
          map_attributes(resource, scope)
        end
      end
    end

  end
end
