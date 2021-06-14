# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'Should create an user' do
    user = User.new
    user.username = 'testing'
    user.password = 'testing'

    assert user.save, 'User not created'
  end

  test 'Should not create a user if username is already taken' do
    test_user = users(:one)

    user = User.new
    user.username = test_user.username
    user.password = 'testing'

    assert_not user.save, 'User created with duplicate username'
  end
end
