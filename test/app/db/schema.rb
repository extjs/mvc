
##
# build simple database
#
# people
#
ActiveRecord::Base.connection.create_table :users, :force => true do |table|
  table.column :id, :serial
  table.column :person_id, :integer
  table.column :password, :string
  table.column :created_at, :date
  table.column :disabled, :boolean, :default => true
end
##
# people
#
ActiveRecord::Base.connection.create_table :people, :force => true do |table|
  table.column :id, :serial
  table.column :first, :string, :null => false
  table.column :last, :string, :null => false
  table.column :email, :string, :null => false
end
##
# user_groups, join table
#
ActiveRecord::Base.connection.create_table :user_groups, :force => true do |table|
  table.column :user_id, :integer
  table.column :group_id, :integer
end

##
# groups
#
ActiveRecord::Base.connection.create_table :groups, :force => true do |table|
  table.column :id, :serial
  table.column :title, :string
end

##
# locations
#
ActiveRecord::Base.connection.create_table :locations, :force => true do |table|
  table.column :id, :serial
  table.column :name, :string
  table.column :street, :string
  table.column :type, :string
end

##
# addresses
#
ActiveRecord::Base.connection.create_table :addresses, :force => true do |table|
  table.column :id, :serial
  table.column :addressable_type, :string
  table.column :addressable_id, :integer
  table.column :street, :string
end

##
# Mock a Model for testing data-types
#
ActiveRecord::Base.connection.create_table :data_types, :force => true do |table|
  table.column :id, :serial
  table.column :string_column, :string
  table.column :decimal_column, :decimal
  table.column :float_column, :float
  table.column :date_column, :date
  table.column :datetime_column, :datetime
  table.column :time_column, :time
  table.column :email, :string
  table.column :integer_column, :integer
  table.column :notnull_column, :string, :null => false
  table.column :default_column, :boolean, :default => true
  table.column :boolean_column, :boolean
end
