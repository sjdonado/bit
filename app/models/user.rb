# frozen_string_literal: true

class User < ApplicationRecord
  validates :username, uniqueness: true
  has_secure_password

  has_many :links, dependent: :nullify
end
