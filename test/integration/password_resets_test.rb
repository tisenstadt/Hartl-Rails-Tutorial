require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end
  
  test "password resets" do
    get new_password_reset_path
    assert_template 'password_resets/new'
    post password_resets_path, password_reset: { email: "" }
    assert_not flash.empty?
    assert_template 'password_resets/new'
    #Valid email
    post password_resets_path, password_reset: { email: @user.email }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest #Reload is pulling from the database
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    user = assigns(:user) #Verifies the @user instance variable and stores it in user for reference in the rest of the test
    #Wrong email
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url
    #Inactive user
    user.toggle!(:activated) #Switches activated status to false
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    #Right email, wrong token
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url
    #Right email, right token
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email
    # Invalid password & confirmation
    patch password_reset_path(user.reset_token),
      email: user.email,
      user: {password: "foobaz",
              password_confirmation: "barquux" }
    #assert_select 'div#error_explanation'
    #Blank password
    patch password_reset_path(user.reset_token),
        email: user.email,
        user: { password:  " ",
                password_confirmation: "foobar" }
    assert_not flash.empty?
    assert_template 'password_resets/edit'
    #Valid passwor & confirmation
    patch password_reset_path(user.reset_token),
      email: user.email,
      user: { password: "foobaz",
              password_confirmaton: "foobaz" }
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
  end
    
    
end
