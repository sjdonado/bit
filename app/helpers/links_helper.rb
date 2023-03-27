# frozen_string_literal: true

module LinksHelper
  def stripped_url(url)
    url.sub(%r{^.*://(www\.)?}, '').sub(/^www\./, '')
  end
end
