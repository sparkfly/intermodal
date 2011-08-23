module Intermodal
  class APIController < ActionController::Metal

    include ActionController::Rendering
    include ActionController::Renderers
    include ActionController::RackDelegation
    include ActionController::Head
    include ActionController::MimeResponds

    include ActionController::Instrumentation
    include AbstractController::Callbacks
    include ActionController::Rescue

    use_renderers :json, :xml

    self.responder = Intermodal::ResourceResponder

    # Major hax
    def render_to_body(options) 
      _handle_render_options(options)
    end

    ActiveSupport.run_load_hooks(:intermodal_api_controller, self)
  end
end
