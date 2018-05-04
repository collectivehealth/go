Sequel.migration do
    change do
        alter_table(:links){ add_foreign_key(:user_id, :users) }
    end
  end