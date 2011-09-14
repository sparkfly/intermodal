module Intermodal
  module Models
    class Account < ActiveRecord::Base
      # Validations
      validates_presence_of :name

      # Associations
      has_many :access_tokens
      has_many :access_credentials
    end
  end
end
