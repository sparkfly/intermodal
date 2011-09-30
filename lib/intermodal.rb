require 'active_support'
require 'will_paginate'

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
  autoload :APIController,             'intermodal/controllers/api_controller'
  autoload :ResourceController,        'intermodal/controllers/resource_controller'
  autoload :NestedResourceController,  'intermodal/controllers/nested_resource_controller'
  autoload :LinkingResourceController, 'intermodal/controllers/linking_resource_controller'

  autoload :ResourceResponder,         'intermodal/responders/resource_responder'
  autoload :LinkingResourceResponder,  'intermodal/responders/linking_resource_responder'

  # Authentication
  # TOOD: Make this more configurable. Not everyone wants X-Auth-Token auth
  module Rack
    autoload :Auth, 'intermodal/rack/auth'
  end

  # Authentication currently require two models
  # Credentials are like passwords.
  # Tokens are like cookie sessions. It currently stores against Redis
  module Models
    autoload :Account,          'intermodal/concerns/models/account'
    autoload :AccessCredential, 'intermodal/concerns/models/access_credential'
    autoload :AccessToken,      'intermodal/concerns/models/access_token'
  end


  ActiveSupport.on_load(:before_initialize) do
    Warden::Strategies.add(:x_auth_token) do
      def valid?
        env['HTTP_X_AUTH_TOKEN']
      end

      def authenticate!
        a = AccessToken.authenticate!(env['HTTP_X_AUTH_TOKEN'])
        a.nil? ? fail!("Could not log in") : success!(a)
      end
    end
  end

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
    autoload :Presentation,    'intermodal/concerns/controllers/presentation'
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

  module Proxies
    autoload :LinkingResources, 'intermodal/proxies/linking_resources'
  end

  # Extensions
  ActiveSupport.on_load(:after_initialize) do
    # Make sure this loads after Will Paginate loads
    require 'intermodal/proxies/will_paginate'

    ::WillPaginate::Collection.send(:include, Intermodal::Proxies::WillPaginate::Collection)
  end

  # Rspec Macros
  module RSpec
    # Models
    autoload :Accountability,    'intermodal/rspec/models/accountability'
    autoload :HasParentResource, 'intermodal/rspec/models/has_parent_resource'
    autoload :ResourceLinking,   'intermodal/rspec/models/resource_linking'

    # Requests
    autoload :Rack,              'intermodal/rspec/requests/rack'
  end
end

require 'intermodal/config'
