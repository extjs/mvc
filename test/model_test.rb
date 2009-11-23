require 'test_helper'

class ModelTest < Test::Unit::TestCase
  context "Rendering DataReader configuration for Person and User" do

	  setup do
	    # common stuff for all tests.
	  end

	  should "Person and User should render a valid Reader config" do
	    reader = Person.extjs_record
	    assert reader.kind_of?(Hash) && reader.has_key?("fields") && reader.has_key?("idProperty")
	  end
	  should "Person instance should render with to_record, a Hash containing at least a primary_key" do
	    rec = Person.first.to_record
	    assert rec.kind_of?(Hash) && rec.keys.include?(Person.extjs_primary_key)
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
  
  context "A User with HABTM relationship with Group" do
    setup do
      UserGroup.destroy_all
      
      @user = User.first
      UserGroup.create(:user => @user, :group => Group.create(:title => "Merb"))
      UserGroup.create(:user => @user, :group => Group.create(:title => "Rails"))
    end
    
    should "Render to_record should return 2 groups" do
      User.extjs_fields(:groups)
      assert @user.to_record["groups"].length == 2
    end
  end

  context "A User with Person relationship: User.extjs_fields(:password, :person => [:first, {:last => {'sortDir' => 'ASC'}}])" do
    setup do
      User.extjs_fields(:password, :person => [:first, {:last => {"sortDir" => "ASC"}}])
	    @fields = User.extjs_record["fields"]
    end
    
    should "User should render a Reader with 4 total fields" do
	    assert @fields.count === 4
    end
    should "Reader fields should contain 'password' field" do
      assert @fields.find {|f| f[:name] === "password"}
    end
    should "Reader fields should contain person_id" do
      assns = User.extjs_associations  
      assn = assns[:person] || assns["person"]
      assert @fields.find {|f| f[:name] === assns[:person][:foreign_key] }
    end
    should "Reader fields should contain mapped field 'person.first'" do
      assert @fields.find {|f| f[:name] === "person_first" and f["mapping"] === "person.first"}
    end
    should "Reader fields should contain mapped field 'person.last'" do
      assert @fields.find {|f| f[:name] === "person_last" and f["mapping"] === "person.last"}
    end
    should "person.last should have additional configuration 'sortDir' => 'ASC'" do
      assert @fields.find {|f| f[:name] === "person_last" and f["sortDir"] === 'ASC' }
    end
  end
  
  context "Fields should render with correct, ExtJS-compatible data-types" do
    setup do
      @fields = DataType.extjs_record["fields"]
    end
    
    should "Understand 'string'" do
      assert @fields.find {|f| f[:name] === 'string_column' && f["type"].to_s === 'string'}
    end
    should "Understand 'integer' as 'int'" do
      assert @fields.find {|f| f[:name] === 'integer_column' && f["type"].to_s === 'int'}
    end
    should "Understand 'float'" do
      assert @fields.find {|f| f[:name] === 'float_column' && f["type"].to_s === 'float'}
    end
    should "Understand 'decimal' as 'float'" do # Is this correct??
      assert @fields.find {|f| f[:name] === 'decimal_column' && f["type"].to_s === 'float'}
    end
    should "Understand 'date'" do
      assert @fields.find {|f| f[:name] === 'date_column' && f["type"].to_s === 'date'}
    end
    should "Understand 'datetime' as 'date'" do
      assert @fields.find {|f| f[:name] === 'datetime_column' && f["type"].to_s === 'date'}
    end
    should "Understand 'time' as 'date'" do
      assert @fields.find {|f| f[:name] === 'time_column' && f["type"].to_s === 'date'}
    end
    should "Understand 'boolean'" do
      assert @fields.find {|f| f[:name] === 'boolean_column' && f["type"].to_s === 'boolean'}
    end
    should "Understand NOT NULL" do
      assert @fields.find {|f| f[:name] === 'notnull_column' && f["allowBlank"] === false}
    end
    should "Understand DEFAULT" do # TODO implement this.
      assert @fields.find {|f| f[:name] === 'default_column' && f["default"] === true}
    end
  end
  
  
end

