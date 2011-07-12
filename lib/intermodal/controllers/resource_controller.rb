module Intermodal
  class ResourceController < ActionController::Base
    include Intermodal::Controllers::Resource

    private
    let(:collection) { model.get(:all, :account => account) }
    let(:object) { model.get(params[:id], :account => account) }
    let(:create_params) { accepted_params.merge( :account_id => env['warden'].user.id ) }
    let(:update_params) { accepted_params }
  end
end
