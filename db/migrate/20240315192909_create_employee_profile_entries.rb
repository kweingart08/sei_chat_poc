class CreateEmployeeProfileEntries < ActiveRecord::Migration[7.1]
  def self.up
    execute "CREATE EXTENSION IF NOT EXISTS vector"

    create_table :employee_profile_entries do |t|
      t.jsonb :metadata, default: {}
      t.text :content
      t.integer :chunk_number
      t.string :chunker_version

      t.timestamps
    end

    execute "ALTER TABLE employee_profile_entries ADD COLUMN vectors VECTOR(1536)"
  end

  def self.down
    drop_table :employee_profile_entries
  end
end