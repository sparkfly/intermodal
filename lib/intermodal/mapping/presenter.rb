module Intermodal
  module Mapping
    class Presenter < Mapper

      self._mapping_strategy = INCLUDE_NILS

      class << self
        alias exclude_from_presentation exclude_properties

        # Convenience alias for maps
        # Examples:
        #
        #  presents :name
        #  presents :name, :with => lambda { |o| o.name.camelize }
        #  presents :name, :with => [ :first_name, :last_name, :suffix, :prefix ]

        alias presents maps

        def model_name(resource)
          resource.class.name.demodulize.underscore
        end

        def call(resource, options = {})
          _scope = options[:scope] || :default

          if options[:root] || options[:always_nest_collections]
            { (options[:root].is_a?(TrueClass) || options[:root].nil? ? model_name(resource) : options[:root]) => map_attributes(resource, _scope) }
          else
            map_attributes(resource, _scope)
          end
        end
      end
    end

  end
end
