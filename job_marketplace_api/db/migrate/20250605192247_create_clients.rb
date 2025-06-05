class CreateClients < ActiveRecord::Migration[7.1]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :email, null: false, index: { unique: true }
      t.string :company_url
      t.string :industry
      t.string :location

      t.timestamps
    end
  end
end
