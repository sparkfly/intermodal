module Intermodal
  module Mapping
    class Mapper
      class_inheritable_accessor :_exclude_properties, :_property_mapping, :_mapping_strategy

      INCLUDE_NILS = lambda { |h, resource, mapped_from, mapped_to| h[mapped_from] = map_attribute(resource, mapped_to) }
      EXCLUDE_NILS = lambda { |h, resource, mapped_from, mapped_to| a = map_attribute(resource, mapped_to); h[mapped_from] = a if a }

      class << self
        def exclude_properties(*args)
          (self._exclude_properties ||= []).push *(args.map(&:to_s))
        end

        def property_mapping
          self._property_mapping ||= []
        end

        # Examples:
        #
        #  maps :name
        #  maps :name, :as => lambda { |o| o.name.camelize }
        #  maps :name, :as => [ :first_name, :last_name, :suffix, :prefix ]
        #
        def maps(property, opts = {})
          property_mapping.push [property, (opts[:as] ? opts[:as] : property)]
        end

        def map_attributes(resource)
          self._property_mapping.inject({}) { |m, p|
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

        def call(resource)
          map_attributes(resource)
        end
      end
    end

  end
end
