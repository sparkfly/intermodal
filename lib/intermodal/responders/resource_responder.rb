require 'action_controller/responder'

module Intermodal
  class ResourceResponder < ActionController::Responder

    attr_accessor :presenter, :presentation_root, :presentation_scope, :always_nest_collections

    def initialize(controller, resources, options={})
      super(controller, resources, options)
      @presenter = options[:presenter]
      @presentation_root = options[:presentation_root]
      @presentation_scope = options[:presentation_scope]
      @always_nest_collections = options[:always_nest_collections]
    end

    # This is the common behavior for "API" requests, like :xml and :json.
    def respond
      return head :status => 404 unless resource
      if get?
        display resource,
          :root => presentation_root,
          :presenter => presenter,
          :scope => presentation_scope,
          :always_nest_collections => always_nest_collections

      elsif has_errors?
        display resource.errors,
          :root => presentation_root,
          :status => :unprocessable_entity,
          :presenter => presenter,
          :scope => presentation_scope,
          :always_nest_collections => always_nest_collections

      elsif post?
        display resource,
          :root => presentation_root,
          :status => :created,
          :presenter => presenter,
          :scope => presentation_scope,
          :always_nest_collections => always_nest_collections
          #:location => api_location # Taken out because it requires some additional URL definitions
      else
        head :ok
      end
    end

    # Refactor to use macro expansion
    def presentation_scope
      @presentation_scope ||= controller.send(:presentation_scope)
    end

    def presentation_root
      @presentation_root ||= controller.send(:presentation_root)
    end

    def presenter
      @presenter ||= controller.send(:presenter)
    end

    def always_nest_collections
      @always_nest_collections || controller.send(:always_nest_collections)
    end
  end
end
