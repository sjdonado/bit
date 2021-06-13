# frozen_string_literal: true

require 'test_helper'

class LinkTest < ActiveSupport::TestCase
  test 'should not save a link without a url' do
    link = Link.new
    assert_not link.save, 'Saved the link without a url'
  end

  test 'should not save a link with a invalid url' do
    link = Link.new
    link.url = 'google.com'
    assert_not link.save, 'Saved the link with invalid url format'
  end
end
