module Intermodal
  class Configuration < ::Rails::Engine::Configuration
    attr_accessor :allow_concurrency

    def initialize(*)
      super
      self.encoding = 'utf-8'
      @allow_concurrency           = false
    end
  end
end
