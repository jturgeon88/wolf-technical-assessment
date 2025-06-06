class AddUniqueIndexToEmailOnJobSeekers < ActiveRecord::Migration[7.1]
  def change
    add_index :job_seekers, :email, unique: true
  end
end
