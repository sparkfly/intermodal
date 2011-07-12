module Intermodal

  # Core
  autoload :Base,               'intermodal/base'
  autoload :DeclareControllers, 'intermodal/declare_controllers'

  module Mapping
    autoload :Mapper,    'intermodal/mapping/mapper'
    autoload :Presenter, 'intermodal/mapping/presenter'
    autoload :Acceptor,  'intermodal/mapping/acceptor'
    autoload :DSL,       'intermodal/mapping/dsl'
  end

  # Controller Templates
  autoload :ResourceController,        'intermodal/controllers/resource_controller'
  autoload :NestedResourceController,  'intermodal/controllers/nested_resource_controller'
  autoload :LinkingResourceController, 'intermodal/controllers/linking_resource_controller'

  autoload :ResourceResponder, 'intermodal/responders/resource_responder'

  # Concerns
  autoload :Let, 'intermodal/concerns/let'

  module Models
    autoload :Accountability,    'intermodal/concerns/models/accountability'
    autoload :HasParentResource, 'intermodal/concerns/models/has_parent_resource'
    autoload :ResourceLinking,   'intermodal/concerns/models/resource_linking'
    autoload :Presentation,      'intermodal/concerns/models/presentation'
  end

  module Controllers
    autoload :Accountability,  'intermodal/concerns/controllers/accountability'
    autoload :Anonymous,       'intermodal/concerns/controllers/anonymous'
    autoload :Resource,        'intermodal/concerns/controllers/resource'
    autoload :ResourceLinking, 'intermodal/concerns/controllers/resource_linking'
  end

  module Acceptors
    autoload :Resource,      'intermodal/concerns/acceptors/resource'
    autoload :NamedResource, 'intermodal/concerns/acceptors/named_resource'
  end

  module Presenters
    autoload :Resource,      'intermodal/concerns/presenters/resource'
    autoload :NamedResource, 'intermodal/concerns/presenters/named_resource'
  end
end
