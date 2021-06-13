# frozen_string_literal: true

class AddSlugIndexToLinks < ActiveRecord::Migration[5.2]
  def change
    add_index :links, :slug
  end
end
