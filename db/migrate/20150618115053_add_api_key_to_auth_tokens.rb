class AddApiKeyToAuthTokens < ActiveRecord::Migration
  def change
  	add_column :auth_tokens, :api_key, :string
  end
end
