# frozen_string_literal: true

require 'test_helper'

class LinkTest < ActiveSupport::TestCase
  test 'Should not save a link without a url' do
    link = Link.new
    assert_not link.save, 'Saved the link without a url'
  end

  test 'Should not save a link with a invalid url' do
    link = Link.new
    link.url = 'test.com'
    assert_not link.save, 'Saved the link with invalid url format'
  end

  test 'Should create a link with a valid url' do
    link = Link.new
    link.url = 'https://test.com'
    assert link.save, 'Link with valid url not saved'
  end

  test 'Should generate a slug on save a new link' do
    link = links(:one)
    assert link.slug, 'Slug not generated on save a new link'
  end
end
