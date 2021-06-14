# frozen_string_literal: true

class Link < ApplicationRecord
  validates_presence_of :url
  validates_uniqueness_of :slug

  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp, message: 'invalid format' }
  validates_length_of :url, within: 3..30_000, on: :create, message: 'max length is 30000'

  before_validation :generate_slug

  def generate_slug
    # Number of combinations 62P6
    self.slug = SecureRandom.alphanumeric(6) if slug.blank?
  end

  def short
    Rails.application.routes.url_helpers.short_url(slug: slug)
  end

  def self.shorten(url)
    link = Link.where(url: url).first
    return link.short if link

    link = Link.new(url: url)
    return link.short if link.save
  end
end
