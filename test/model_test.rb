require 'test_helper'


class ModelTest < Test::Unit::TestCase
  context "A Model instance" do

	  setup do
	    # common stuff for all tests.
	  end

	  should "Person should render a Reader config" do
	    reader = Person.extjs_record
	    assert reader.kind_of?(Hash) && reader.has_key?("fields") && reader.has_key?("idProperty")
	  end
	  
	  should "User should render a Reader config" do
	    reader = User.extjs_record
	    assert reader.kind_of?(Hash) && reader.has_key?("fields") && reader.has_key?("idProperty")
	  end
	  
	  should "User instance should render with to_record, a Hash containing at least a primary_key" do
	    rec = User.first.to_record
	    assert rec.kind_of?(Hash) && rec.keys.include?(User.extjs_primary_key)
	  end
	  
  end
  
end

