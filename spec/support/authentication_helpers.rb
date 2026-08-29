module AuthenticationHelpers
  def sign_in(user, password: "password")
    post postnhost.session_path, params: { user: { email: user.email, password: } }
  end
end
