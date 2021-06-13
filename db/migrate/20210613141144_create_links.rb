# frozen_string_literal: true

class CreateLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :links do |t|
      t.string :slug, null: false
      t.text :url
      t.integer :click_counter, default: 0

      t.timestamps
    end
  end
end
