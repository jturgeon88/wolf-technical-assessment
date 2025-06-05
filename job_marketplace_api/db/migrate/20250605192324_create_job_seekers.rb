class CreateJobSeekers < ActiveRecord::Migration[7.1]
  def change
    create_table :job_seekers do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :resume_url

      t.timestamps
    end
  end
end
