require 'spec_helper'

module SpecHelpers
  module Application
    extend ActiveSupport::Concern

    included do
      # Authentication
      let(:account) { Account.make! }
      let(:access_credential) { AccessCredential.make!(:account => account) }
      let(:access_token) { AccessToken.generate!(account) }

      # Example for top-level resource
      let(:item) { Item.make!(:account => account) }
      let(:part) { Part.make!(:item => item) }
    end
  end
end
