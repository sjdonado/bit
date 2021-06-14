# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  test 'Should create an user' do
    params = { user: { username: 'testing', password: 'testing', confirm_password: 'testing' } }
    post users_url, params: params

    assert_response :success
  end

  test 'Should return 400 on create an user without confirm_password' do
    user = users(:one)
    params = { user: { username: user.username, password: 'testing' } }
    post users_url, params: params

    assert_response :bad_request
  end

  test 'Should return 422 on create an user with existing username' do
    user = users(:one)
    params = { user: { username: user.username, password: 'testing', confirm_password: 'testing' } }
    post users_url, params: params

    assert_response :unprocessable_entity
  end
end
