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
  
  context "A User with with Person relationship: User.extjs_fields(:password, :person => [:first, :last])" do
    setup do
      User.extjs_fields(:password, :person => [:first, :last])
	    @fields = User.extjs_record["fields"]
    end
    
    should "User should render a Reader with 4 total fields" do
	    assert @fields.count === 4
    end
    
    should "Reader fields should contain 'password' field" do
      assert @fields.find {|f| f[:name] === "password"}
    end
    
    should "Reader fields should contain person_id" do
      assert @fields.find {|f| f[:name] === "person_id" }
    end
    
    should "Reader fields should contain mapped field 'person.first'" do
      assert @fields.find {|f| f[:name] === "person_first" and f["mapping"] === "person.first"}
    end
    
    should "Reader fields should contain mapped field 'person.last'" do
      assert @fields.find {|f| f[:name] === "person_last" and f["mapping"] === "person.last"}
    end
    
  end

end

