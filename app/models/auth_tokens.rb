class AuthTokens < ActiveRecord::Base
  ## this is the model for all the authentication tokens stored to identify a user through cookie / session
  belongs_to :user
  validates :user_id, :presence => true
  validates :token, :presence => true
  validates :expires, :presence => true

  def self.get_user user_token
    #checks a token and returns the user
    raise DBArgumentError.new "missing token" if user_token.blank?
    tok = AuthTokens.find_by_token(user_token)
    raise DBArgumentError.new "Invalid Token" if tok.blank?
    raise DBArgumentError.new "Token Expired" if tok.expires < Time.now
    user = tok.user
    raise DBArgumentError.new "No user for this token" if user.blank?
    return user
  end


  def update_token
    ## changes the token and gives it
    self.token = SecureRandom.base64(32)
    self.save
    return self.token
  end



end
