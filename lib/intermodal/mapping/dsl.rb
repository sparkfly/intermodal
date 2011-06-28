module Intermodal
  module Mapping
    module DSL
      extend ActiveSupport::Concern

      included do
        class_inheritable_accessor :_presentation_description, :_presenters, :_acceptors
      end

      module ClassMethods
        # DSL
        def map_data(&blk)
          self._presentation_description = blk
        end

        def presentation_for(resource, &customizations)
          model = resource.to_s.camelize.constantize

          model.send(:include, Models::Presentation)
          presenter_template = Class.new(Presenter)
          presenter_template._property_mapping = []
          presenter_template.instance_eval(&customizations)
          presenters[resource.to_sym] = presenter_template
        end

        def acceptance_for(resource, &customizations)
          model = resource.to_s.camelize.constantize

          #model.send(:include, Models::Acceptance)
          acceptor = Class.new(Acceptor)
          acceptor._property_mapping = []
          acceptor.instance_eval(&customizations)
          acceptors[resource.to_sym] = acceptor
        end

        # Setup
        def load_presentations!
          self._presentation_description.call
        end

        # Accessors
        def presenters
          self._presenters ||= {}
        end

        def presenter_for(model)
          presenters[model_name(model)]
        end

        def acceptors
          self._acceptors ||= {}
        end

        def acceptor_for(model)
          acceptors[model_name(model)]
        end

        def model_name(model)
          model.name.underscore.to_sym
        end

        def resource_name(resource)
          model_name(resource.class)
        end

        def presents_resource(resource) 
          presenters[resource_name(resource)].call(resource)
        end

        def accepts_resource(resource) 
          accepts[resource_name(resource)].call(resource)
        end
      end
    end
  end
end
