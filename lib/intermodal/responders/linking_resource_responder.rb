require 'action_controller/responder'

module Intermodal
  class LinkingResourceResponder < ResourceResponder

    # This is the common behavior for "API" requests, like :xml and :json.
    def respond
      if get?
        display resource, :root => presentation_root
      elsif has_errors?
        display resource.errors, :status => :unprocessable_entity
      elsif post?
        display resource, :status => :created
          #:location => api_location # Taken out because it requires some additional URL definitions
      else
        head :ok
      end
    end

  end
end
