# frozen_string_literal: true

class AddUsernameIndexToUsers < ActiveRecord::Migration[5.2]
  def change
    add_index :users, :username, unique: true
  end
end
