module Intermodal
  module Controllers
    module Presentation
      extend ActiveSupport::Concern

      included do
        include Intermodal::Let

        let(:api) { self.class.api }
        let(:presenter) { api.presenters[model_name] }
        let(:acceptor) { api.acceptors[model_name] }
        let(:accepted_params) { acceptor.call(params[resource_name] || {}) }
      end
    end
  end
end
