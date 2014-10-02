# Sets up Intermodal on Rails
class IntermodalGenerator < Rails::Generators::Base
  def create_initializer_file
    generate "model", "account name:string --timestamps"
    generate "model", "access_token account_id:integer token:string" # Needs foreign key
    generate "model", "access_credential account_id:integer identity:string key:string" # Needs foreign key
  end
end
