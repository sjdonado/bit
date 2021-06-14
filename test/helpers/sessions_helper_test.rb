# frozen_string_literal: true

require 'test_helper'

class SessionsHelperTest < ActionView::TestCase
  test 'Should return current_user username' do
    @current_user = users(:one)
    assert_equal @current_user.username, current_user_username
  end

  test 'Should return nil if current_user is nil' do
    assert_nil current_user_username
  end
end
