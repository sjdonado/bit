# frozen_string_literal: true

require 'test_helper'

class LinksControllerTest < ActionDispatch::IntegrationTest
  test 'Should get Home page' do
    get '/'
    assert_response :success, 'Not rendered home page'
  end

  test 'Should return 404 for unavailable slug' do
    get '/test'
    assert_response :not_found, 'Not rendered not found'
  end

  test 'Should redirect from slug to url' do
    link = links(:one)
    slug = link.slug
    get short_url(slug: slug)

    assert_redirected_to link.url, 'Not redirected to link url'
  end
end
