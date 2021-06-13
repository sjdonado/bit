# frozen_string_literal: true

require 'test_helper'

class LinkTest < ActiveSupport::TestCase
  test 'should not save a link without a url' do
    link = Link.new
    assert_not link.save, 'Saved the link without a url'
  end

  test 'should not save a link with a invalid url' do
    link = Link.new
    link.url = 'test.com'
    assert_not link.save, 'Saved the link with invalid url format'
  end

  test 'should create a link with a valid url' do
    link = Link.new
    link.url = 'https://test.com'
    assert link.save, 'Link with valid url not saved'
  end

  test 'should generate a slug on save a new link' do
    link = links(:one)
    assert link.slug, 'Slug not generated on save a new link'
  end

  test 'should get shorten url of existing url' do
    link = links(:one)
    url = link.url
    assert Link.shorten(url), 'Shorten url not found'
  end

  test 'should get shorten url and create a link' do
    url = 'https://test.com'
    assert Link.shorten(url), 'Link not created'
  end
end
