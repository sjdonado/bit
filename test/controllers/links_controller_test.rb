# frozen_string_literal: true

require 'test_helper'

class LinksControllerTest < ActionDispatch::IntegrationTest
  test 'Should get index page' do
    get '/'
    assert_response :success, 'Not rendered index page'
  end

  test 'Should return 404 for unavailable slug' do
    get '/test'
    assert_response :not_found, 'Not rendered not found'
  end

  test 'Should create a link' do
    url = 'https://test.com'
    post links_url, params: { link: { url: url } }

    assert_response :success, 'Link not created'
  end

  test 'Should return 422 on create an invalid link' do
    url = 'test'
    post links_url, params: { link: { url: url } }

    assert_response :unprocessable_entity, 'Invalid link created'
  end

  test 'Should redirect from slug to url' do
    link = links(:one)
    slug = link.slug
    get short_url(slug: slug)

    assert_redirected_to link.url, 'Not redirected to link url'
  end
end
