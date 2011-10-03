require 'spec_helper'

module SpecHelpers
  module Application
    extend ActiveSupport::Concern

    included do
      include SpecHelpers::ClassBuilder

      # Authentication. These need to be defined globally
      let(:account) { Account.make! }
      let(:different_account) { Account.make! }
      let(:access_credential) { AccessCredential.make!(:account => account) }
      let(:access_token) { AccessToken.generate!(account) }

      # Example for top-level resource
      let(:item) { Item.make!(:account => account) }
      let(:part) { Part.make!(:item => item) }
      let(:vendor) { Item.make!(:account => account) }
      let(:sku) { Sku.make!(:item => item, :vendor => vendor) }
    end
  end
end
