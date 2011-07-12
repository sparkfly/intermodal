module Intermodal
  class ResourceResponder < ActionController::Responder

    # This is the common behavior for "API" requests, like :xml and :json.
    def to_format

      if get?
        display resource
      elsif has_errors?
        display resource.errors, :status => :unprocessable_entity
      elsif post?
        display resource, :status => :created, :location => api_location
      else
        head :ok
      end
    end
  end
end
