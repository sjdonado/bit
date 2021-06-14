# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  test 'Should create an user' do
    params = { user: { username: 'testing', password: 'testing' } }
    post users_url, params: params

    assert_redirected_to '/'
  end

  test 'Should return 422 with existing username' do
    user = users(:one)
    params = { user: { username: user.username, password: 'testing' } }
    post users_url, params: params

    assert_response :unprocessable_entity
  end
end
