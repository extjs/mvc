class Group < ActiveRecord::Base
  has_many :users
  include ExtJS::Model
end