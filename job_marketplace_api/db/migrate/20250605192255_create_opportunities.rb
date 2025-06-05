class CreateOpportunities < ActiveRecord::Migration[7.1]
  def change
    create_table :opportunities do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.integer :salary, null: false
      t.string :location
      t.string :employment_type
      t.boolean :remote, default: false
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
  end
end
