module Intermodal
  class Base
    include Intermodal::Mapping::DSL
    extend Intermodal::DeclareControllers
    class_inheritable_accessor :routes

    def self.inherited(klass)
      ActiveSupport.on_load(:after_initialize) do
        klass.load_presentations!
      end
    end
  end
end
