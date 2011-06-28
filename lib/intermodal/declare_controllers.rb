module Intermodal
  module DeclareControllers
    attr_accessor :controller_definitions

    def controllers(&blk)
      self.controller_definitions = blk
    end

    def resources(name, &blk)
      controller_name = _controller_name(name)
      _create_controller(name, controller_name, blk, :ancestor => ResourceController, :api => self)
    end

    def nested_resources(parent_name, name, options = {}, &blk)
      _parent_model = options[:parent_model]
      _parent_resource = parent_name.to_s.singularize.to_sym
      _namespace = _module(parent_name)
      controller_name = _controller_name(name)

      _create_controller(name, controller_name, blk, 
                         :ancestor => NestedResourceController, 
                         :namespace => _namespace,
                         :model => options[:model],
                         :parent_resource => _parent_resource,
                         :parent_model => _parent_model,
                         :api => self) 
    end

    def link_resources_from(parent_name, options = {}, &blk)
      _model = options[:model]
      _parent_model = options[:parent_model]
      _parent_resource = parent_name.to_s.singularize.to_sym
      _target_resource = options[:to]
      _namespace = _module(parent_name)
      controller_name = _controller_name(_target_resource)

      customize_linking_resource = proc do
        let(:model) { _model }
        let(:target_ids) { params[_target_resource] }
      end

      controller = _create_controller(name, controller_name, customize_linking_resource, 
                                      :ancestor => LinkingResourceController, 
                                      :namespace => _namespace,
                                      :model => _model,
                                      :parent_resource => _parent_resource,
                                      :parent_model => _parent_model) 
      controller.instance_eval(&blk) if blk
    end

    def load_controllers!
      self.controller_definitions.call
    end

    # API: private
    def _create_controller(resource_name, controller_name, customizations, options = {},  &blk)
      _ancestor = options[:ancestor] || ApplicationController
      _namespace = options[:namespace] || Object

      _unload_controller_if_exists(controller_name, _namespace)
      controller = Class.new(_ancestor)
      _namespace.const_set(controller_name, controller)
      Rails.logger.warn "Creating new resource controller: #{_namespace}::#{controller}"

      controller.resource = resource_name
      controller.model = options[:model] if options[:model]
      controller.parent_resource = options[:parent_resource] if options[:parent_resource]
      controller.parent_model = parent_model if options[:parent_model]
      controller.class_eval(&customizations) if customizations
      controller.api = options[:api] if options[:api]

      Rails.logger.info "New class: #{controller.inspect}: #{controller.controller_name}"
      controller
    end

    def _controller_name(name)
      case name
      when String then name.to_s
      when Symbol then "#{name.to_s.camelize}Controller"
      else
        raise "resources require String or Symbol"
      end
    end

    def _module(module_name)
      module_name = module_name.to_s.camelize
      if Object.const_defined?(module_name)
        module_name.constantize
      else
        Object.const_set(module_name, Module.new)
      end
    end

    def _unload_controller_if_exists(controller_name, _namespace = Object)
      begin
        _namespace.send(:remove_const, controller_name) if _namespace.const_defined?(controller_name) # Unload existing class
      rescue Exception => err
        Rails.logger.warn "Unable to unload #{controller_name}: #{err.inspect}"
      end
    end
  end
end
