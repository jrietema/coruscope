module CmsDeviseAuth

  # enable devise authentication
  def authenticate
    authenticate_user!
    unless user_signed_in? && current_user
      redirect_to new_user_session_path
    end
  end
end
