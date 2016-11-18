require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
 
  def setup
    ActionMailer::Base.deliveries.clear
  end
 
  test "invalid signup information" do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, user: { name: "",
                               email: "user@invalid",
                               password: "foo",
                               password_confirmation: "bar" }
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation'
    assert_select 'div.field_with_errors'
  end
  
  test "valid signup information" do
    get signup_path
    assert_difference 'User.count', 1 do #This user should be in the database now, even though he or she has not been activated.
      post users_path, user: { name: "Example User",
                               email: "user@example.com",
                               password: "password",
                               password_confirmation: "password" }
      end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user) #Assigns allows access to controller instance variables in tests. The create controller action created the @user instance variable, which we access here.
    assert_not user.activated?
    log_in_as(user) #Should fail as user is not activated
    assert_not is_logged_in? #The session was not generated.
    get edit_account_activation_path("invalid token")
    assert_not is_logged_in?
    get edit_account_activation_path(user.activation_token, email: 'wrong')
    assert_not is_logged_in?
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect! 
    assert_template 'users/show'
    assert is_logged_in?
  end
    
                               
end
