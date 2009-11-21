require 'rubygems'
require 'test/unit'
require 'shoulda'

require 'active_record'
require 'active_support'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'extjs-mvc'
########################################
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
#
class User < ActiveRecord::Base
  include ExtJS::Model
  belongs_to :person
end

class Person < ActiveRecord::Base
  include ExtJS::Model
end

class Test::Unit::TestCase
end

##
# build simple database
#
ActiveRecord::Base.connection.create_table :users, :force => true do |table|
  table.column :id, :serial
  table.column :person_id, :integer
  table.column :password, :string
end

ActiveRecord::Base.connection.create_table :people, :force => true do |table|
  table.column :id, :serial
  table.column :first, :string
  table.column :last, :string
  table.column :email, :integer
end

##
# create a couple of related instances.
#
p = Person.create(:first => "Chris", :last => "Scott", :email => "chris@scott.com")
u = User.create(:password => "1234", :person => p)