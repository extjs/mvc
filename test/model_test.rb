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
	    assert rec.kind_of?(Hash) && rec.keys.include?(Person.extjs_primary_key.to_s)
	  end
	  should "User should render a Reader config" do
	    reader = User.extjs_record
	    assert reader.kind_of?(Hash) && reader.has_key?("fields") && reader.has_key?("idProperty")
	  end
	  should "User instance should render with to_record, a Hash containing at least a primary_key" do
	    rec = User.first.to_record
	    assert rec.kind_of?(Hash) && rec.keys.include?(User.extjs_primary_key.to_s)
	  end
	  should "User instance should render to_record containing foreign_key of Person" do
	    rec = User.first.to_record
	    assn = User.extjs_associations[:person]
	    assert rec.keys.include?(assn[:foreign_key])
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
    
    should "produce a valid to_record record" do
      person = Person.create!(:first => 'first', :last => 'last', :email => 'email')
      user = User.create!(:person_id => person.id, :password => 'password')
      record = user.to_record
      assert_equal(user.id, record['id'])
      assert_equal(person.id, record['person_id'])
      assert_equal('password', record['password'])
      assert_equal('last', record['person']['last'])
      assert_equal('first', record['person']['first'])
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
  
  context "polymorphic assosiations should work" do

    should "return nil as class for a polymorphic relation" do
      assert_equal(nil, Address.extjs_associations[:addressable][:class])
    end
    
    should "create a proper default store config" do
      Address.extjs_fields
      fields = Address.extjs_record["fields"]
      assert fields.find {|f| f[:name] === 'addressable_id' && !f["mapping"] }
      assert fields.find {|f| f[:name] === 'addressable_type' && !f["mapping"] }
    end
    
    should "create the right store config when including members of the polymorpic association" do
      Address.extjs_fields :street, :addressable => [:name]
      fields = Address.extjs_record['fields']
      assert fields.find {|f| f[:name] === 'addressable_name' && f["mapping"] === 'addressable.name'}
      assert fields.find {|f| f[:name] === 'addressable_id' && !f["mapping"] }
      assert fields.find {|f| f[:name] === 'addressable_type' && !f["mapping"] }
    end
    
    should "fill in the right values for to_record" do
      Address.extjs_fields :street, :addressable => [:name]
      location = Location.create!(:name => 'Home')
      address = location.create_address(:street => 'Main Street 1')
      record = address.to_record
      assert_equal({"name"=>"Home"}, record["addressable"])
      assert_equal("Location", record["addressable_type"])
      assert_equal(location.id, record["addressable_id"])
      assert_equal(address.id, record["id"])
      assert_equal("Main Street 1", record["street"])
    end
  end
  
  
end

