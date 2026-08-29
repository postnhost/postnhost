module SystemTestHelpers
  def sign_in_as(user, password: "password")
    visit postnhost.new_session_path
    find_field("user_email", visible: :all).set(user.email)
    find_field("user_password", visible: :all).set(password)
    page.execute_script("document.querySelector('form').requestSubmit()")

    expect(page).to have_current_path(postnhost.articles_path, ignore_query: true, wait: 5)
  end

  def sign_in_fast(user)
    page.set_rack_session(user_id: user.id) if page.respond_to?(:set_rack_session)
  end
end
