# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class LinkTest < ActiveSupport::TestCase
  test 'Should not save a link without a url' do
    link = Link.new
    assert_not link.save, 'Saved the link without a url'
  end

  test 'Should not save a link with a invalid url - number' do
    link = Link.new
    link.url = 0
    assert_not link.save, 'Saved the link with invalid url format'
  end

  test 'Should not save a link with a invalid url - string' do
    link = Link.new
    link.url = 'test'
    assert_not link.save, 'Saved the link with invalid url format'
  end

  test 'Should generate a slug on save a new link - format https://google.com' do
    link = links(:one)
    assert link.save, 'Slug generated on save a new link'
  end

  test 'Should generate a slug on save a new link - format http://www.google.com' do
    link = links(:two)
    assert link.save, 'Slug generated on save a new link'
  end

  test 'Should generate a slug on save a new link - format google.com' do
    link = links(:three)
    assert link.save, 'Slug generated on save a new link'
  end

  test 'Should generate an unique slug' do
    SecureRandom.stub :alphanumeric, 'ktr4ms' do
      link = Link.new
      link.url = 'https://test.sjdonado.de'
      link.generate_slug
      assert_raise(ActiveRecord::NotNullViolation) { link.save }
    end
  end
end
