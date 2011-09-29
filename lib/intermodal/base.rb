module Intermodal
  class Base
    include Intermodal::Mapping::DSL
    extend Intermodal::DeclareControllers
    class_attribute :routes, :max_per_page, :default_per_page

    # Configure
    self.max_per_page = Intermodal.max_per_page
    self.default_per_page = Intermodal.default_per_page

    def self.inherited(klass)
      ActiveSupport.on_load(:after_initialize) do
        klass.load_presentations!
      end
    end
  end
end
