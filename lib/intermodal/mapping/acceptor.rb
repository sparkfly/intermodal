module Intermodal
  module Mapping
    class Acceptor < Mapper

      self._mapping_strategy = EXCLUDE_NILS

      class << self
        alias exclude_from_acceptance exclude_properties 

        # Convenience alias to maps
        # Examples:
        #
        #  accepts :name
        #  accepts :name, :as => lambda { |o| o.name.camelize }
        #  accepts :name, :as => [ :first_name, :last_name, :suffix, :prefix ]
        #
        alias accepts maps
      end
    end

  end
end
