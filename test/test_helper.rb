require 'rubygems'
require 'test/unit'
require 'shoulda'

require 'active_record'
require 'active_support'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'extjs-mvc'

gem 'sqlite3-ruby'

begin
  require 'ruby-debug'
rescue LoadError
  puts "ruby-debug not loaded"
end

ROOT       = File.join(File.dirname(__FILE__), '..')
RAILS_ROOT = ROOT
RAILS_ENV  = "test"

FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures") 
config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config['test'])

##
# build User / Person models
# Move AR-specific stuff to AR test adapter
#
class User < ActiveRecord::Base
  include ExtJS::Model
  belongs_to :person
  #has_many :user_groups
  #has_many :groups, :through => :user_groups
  has_and_belongs_to_many :groups, :join_table => :user_groups
  
end

class Person < ActiveRecord::Base
  has_one :user
  include ExtJS::Model
end

class DataType < ActiveRecord::Base
  include ExtJS::Model
end

class UserGroup < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
end

class Group < ActiveRecord::Base
  has_many :users
  include ExtJS::Model
end

class Location < ActiveRecord::Base
  has_one :address, :as => :addressable
  #include ExtJS::Model
end
class Address < ActiveRecord::Base
  belongs_to :addressable, :polymorphic => true
  include ExtJS::Model
end

class Test::Unit::TestCase
end

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

##
# create a couple of related instances.
#
p = Person.create(:first => "Chris", :last => "Scott", :email => "chris@scott.com")
u = User.create(:password => "1234", :person => p)


