require 'responders'

module Intermodal
  class APIController < ActionController::Metal

    include AbstractController::Rendering
    include ActionController::Rendering
    include ActionController::Renderers
    include ActionController::RackDelegation
    include ActionController::Head
    include ActionController::MimeResponds

    include ActionController::Instrumentation
    include AbstractController::Callbacks
    include ActionController::Rescue

    include ActionController::RespondWith
    include Intermodal::Controllers::Presentation

    use_renderers :json, :xml

    self.responder = Intermodal::ResourceResponder

    ActiveSupport.run_load_hooks(:intermodal_api_controller, self)
  end
end
