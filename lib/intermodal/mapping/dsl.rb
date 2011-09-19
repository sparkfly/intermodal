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

        # TODO: Consolidate with acceptance_for
        def presentation_for(resource, &customizations)
          model = resource.to_s.camelize.constantize

          model.send(:include, Intermodal::Models::Presentation)
          presenter_template = Class.new(Presenter)
          presenter_template.api = self
          presenter_template._property_mappings = {}
          presenter_template.instance_eval(&customizations)
          presenters[resource.to_sym] = presenter_template
        end

        # TODO: Consolidate with presentation_for
        def acceptance_for(resource, &customizations)
          model = resource.to_s.camelize.constantize

          #model.send(:include, Models::Acceptance)
          acceptor = Class.new(Acceptor)
          acceptor.api = self
          acceptor._property_mappings = {}
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

        def presents_resource(resource, options = {})
          presenters[resource_name(resource)].call(resource, options)
        end

        def accepts_resource(resource, options = {})
          accepts[resource_name(resource)].call(resource, options)
        end
      end
    end
  end
end
