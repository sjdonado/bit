# frozen_string_literal: true

class AddUserIdToLinks < ActiveRecord::Migration[5.2]
  def change
    add_reference :links, :user, foreign_key: true
  end
end
