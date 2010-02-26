class Person < ActiveRecord::Base
  has_one :user
  include ExtJS::Model
end