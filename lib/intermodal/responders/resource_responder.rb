module Intermodal
  class ResourceResponder < ActionController::Responder

    # This is the common behavior for "API" requests, like :xml and :json.
    def respond
      if get?
        display resource, :presenter => presenter
      elsif has_errors?
        display resource.errors, :status => :unprocessable_entity, :presenter => presenter
      elsif post?
        display resource, :status => :created, :presenter => presenter
          #:location => api_location # Taken out because it requires some additional URL definitions
      else
        head :ok
      end
    end

    def presenter
      controller.send(:presenter)
    end
  end
end
