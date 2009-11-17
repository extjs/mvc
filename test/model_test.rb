require 'test_helper'

class TestParent < ActiveRecord::Base

end

class TestModel < ActiveRecord::Base
  include ExtJS::Model
  belongs_to :test_parent

  #for the EXT Store configuration
  extjs_fields :name, :test_parent => [:name]
end

class ModelTest < Test::Unit::TestCase
  def test_field_list_for_associations
    assert_equal [[:test_parent, :name], :name, :id], TestModel.extjs_fields
  end
end

