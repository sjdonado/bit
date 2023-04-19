# frozen_string_literal: true

require 'test_helper'

class LinksControllerTest < ActionDispatch::IntegrationTest
  test 'Should get index page' do
    get '/'
    assert_response :success
  end

  test 'Should return 404 for unavailable slug' do
    get '/test'
    assert_response :not_found
  end

  test 'Should create a link' do
    url = 'https://test.sjdonado.de'
    post links_url, params: { link: { url: url } }

    assert_response :success
  end

  test 'Should create a link with user' do
    user = users(:one)
    post login_url, params: { username: user.username, password: '12345' }

    assert_response :success

    url = 'https://test.sjdonado.de'
    post links_url, params: { link: { url: url } }

    assert_response :success
  end

  test 'Should return 422 on create an invalid link' do
    url = 'test'
    post links_url, params: { link: { url: url } }

    assert_response :unprocessable_entity
  end

  test 'Should redirect from slug to url' do
    link = links(:one)
    slug = link.slug

    get short_url(slug: slug)

    assert_redirected_to link.parsed_url
  end

  test 'Should get link counter' do
    link = links(:one)
    get counter_url(slug: link.slug)

    assert_response :success
  end

  test 'Should return 404 on get counter with an invalid slug' do
    get counter_url(slug: 'test')

    assert_response :not_found
  end
end
