Sequel.migration do
  up do
    create_table :users do
      primary_key :id
      String :name, :unique => true, :null => false
      String :email, :unique => false, :null => false
      DateTime :created_at
      index :name
    end
  end

  down do
    drop_table(:user)
  end
end