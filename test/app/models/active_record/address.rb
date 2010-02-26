class Address < ActiveRecord::Base
  belongs_to :addressable, :polymorphic => true
  include ExtJS::Model
end