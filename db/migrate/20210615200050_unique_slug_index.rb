# frozen_string_literal: true

class UniqueSlugIndex < ActiveRecord::Migration[5.2]
  def change
    remove_index :links, column: :slug
    add_index :links, :slug, unique: true
  end
end
