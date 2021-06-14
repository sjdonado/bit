# frozen_string_literal: true

require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'Should create an user session' do
    user = users(:one)
    params = { username: user.username, password: '12345' }
    post login_url, params: params

    assert_response :success
  end

  test 'Should return 401 with not available user' do
    params = { username: nil, password: 'test' }
    post login_url, params: params

    assert_response :unauthorized
  end

  test 'Should return 401 with wrong credentials' do
    user = users(:one)
    params = { username: user.username, password: 'test' }
    post login_url, params: params

    assert_response :unauthorized
  end

  test 'Should destroy session' do
    get logout_url

    assert_response :success
  end
end
