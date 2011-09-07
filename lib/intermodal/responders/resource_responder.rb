module Intermodal
  class ResourceResponder < ActionController::Responder

    attr_accessor :presenter, :presentation_root

    def initialize(controller, resources, options={})
      super(controller, resources, options)
      @presenter = options[:presenter]
      @presentation_root = options[:presentation_root]
    end

    # This is the common behavior for "API" requests, like :xml and :json.
    def respond
      if get?
        display resource, :root => presentation_root, :presenter => presenter
      elsif has_errors?
        display resource.errors, :root => presentation_root, :status => :unprocessable_entity, :presenter => presenter
      elsif post?
        display resource, :root => presentation_root, :status => :created, :presenter => presenter
          #:location => api_location # Taken out because it requires some additional URL definitions
      else
        head :ok
      end
    end

    def presentation_root
      @presentation_root ||= controller.send(:presentation_root)
    end

    def presenter
      @presenter ||= controller.send(:presenter)
    end
  end
end
