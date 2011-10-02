module Intermodal
  module Mapping
    module DSL
      extend ActiveSupport::Concern

      attr_accessor :_presentation_description, :_presenters, :_acceptors

      # DSL
      def map_data(&blk)
        self._presentation_description = blk
      end

      def mapping_for(resource, mapper, &customizations)
        Class.new(mapper).tap do |template|
          template.api = self
          template._property_mappings = {}
          template.instance_eval(&customizations)
        end
      end

      def presentation_for(resource, &customizations)
        presenters[resource.to_sym] = mapping_for(resource, Presenter, &customizations)
      end

      def acceptance_for(resource, &customizations)
        acceptors[resource.to_sym] = mapping_for(resource, Acceptor, &customizations)
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
