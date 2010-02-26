require 'test_helper'

##
# create a couple of related instances.
#
p = Person.create(:first => "Chris", :last => "Scott", :email => "chris@scott.com")
u = User.create(:password => "1234", :person => p)

class BogusModel
  include ExtJS::Model
  class << self
    def extjs_allow_blank(col)
      true
    end
    
    def extjs_default(col)
      nil
    end
    
    def extjs_type(col)
      nil
    end
    
    def extjs_column_names
      [:one, :two, :three_id]
    end
    
    def extjs_columns_hash
      {
        :one   => {},
        :two   => {},
        :three_id => {}
      }
    end
    
    def extjs_polymorphic_type(id_column_name)
      id_column_name.to_s.gsub(/_id\Z/, '_type').to_sym
    end
    
    def extjs_primary_key
      :id
    end
 
    def extjs_associations
      {
        :three => {
          :name => :tree,
          :type => :belongs_to,
          :class => nil,
          :foreign_key => :three_id,
          :is_polymorphic => false
        }
      }
    end
  end
end


class BogusModelChild < BogusModel
end

class ModelTest < Test::Unit::TestCase
  context "Rendering DataReader configuration for Person and User" do

	  setup do
	    App.clean_all
	  end

	  should "Person and User should render a valid Reader config" do
	    reader = Person.extjs_record
	    assert reader.kind_of?(Hash) && reader.has_key?(:fields) && reader.has_key?(:idProperty)
	  end
	  should "Person instance should render with to_record, a Hash containing at least a primary_key" do
	    rec = Person.first.to_record
	    assert_kind_of(Hash, rec)
	    assert_array_has_item(rec.keys, 'has primary key') { |i| i.to_s == Person.extjs_primary_key.to_s }
	  end
	  should "User should render a Reader config" do
	    reader = User.extjs_record
	    assert reader.kind_of?(Hash) && reader.has_key?(:fields) && reader.has_key?(:idProperty)
	  end
	  should "User instance should render with to_record, a Hash containing at least a primary_key" do
	    rec = User.first.to_record
	    assert rec.kind_of?(Hash) && rec.keys.include?(User.extjs_primary_key)
	  end
	  should "User instance should render to_record containing foreign_key of Person" do
	    rec = User.first.to_record
	    assn = User.extjs_associations[:person]
	    assert rec.keys.include?(assn[:foreign_key])
	  end
	  
  end
  
  context "A User with HABTM relationship with Group" do
    setup do
      App.clean_all
      UserGroup.destroy_all
      
      @user = User.first
      UserGroup.create(:user => @user, :group => Group.create(:title => "Merb"))
      UserGroup.create(:user => @user, :group => Group.create(:title => "Rails"))
    end
    
    should "Render to_record should return 2 groups" do
      User.extjs_fields(:groups)
      assert @user.to_record[:groups].length == 2
    end
  end

  context "A User with Person relationship: User.extjs_fields(:password, :person => [:first, {:last => {'sortDir' => 'ASC'}}])" do
    setup do
      App.clean_all
      User.extjs_fields(:password, {:person => [:first, {:last => {:sortDir => "ASC"}}]})
	    @fields = User.extjs_record[:fields]
    end
    
    should "User should render a Reader with 4 total fields" do
	    assert @fields.count === 4
    end
    should "Reader fields should contain 'password' field" do
      assert_array_has_item(@fields, 'has password field') {|f| f[:name] === "password"}
    end
    should "Reader fields should contain person_id" do
      assns = User.extjs_associations  
      assn = assns[:person]
      assert_array_has_item(@fields, 'has foreign key person_id') {|f| f[:name] === assns[:person][:foreign_key].to_s }
    end
    should "Reader fields should contain mapped field 'person.first'" do
      assert_array_has_item(@fields, 'has person_first') {|f| f[:name] === "person_first" and f[:mapping] === "person.first"}
    end
    should "Reader fields should contain mapped field 'person.last'" do
      assert_array_has_item(@fields, 'has person_last') {|f| f[:name] === "person_last" and f[:mapping] === "person.last"}
    end
    should "person.last should have additional configuration 'sortDir' => 'ASC'" do
      assert_array_has_item(@fields, 'has person.last with sortDir') {|f| f[:name] === "person_last" and f[:sortDir] === 'ASC' }
    end
    
    should "produce a valid to_record record" do
      person = Person.create!(:first => 'first', :last => 'last', :email => 'email')
      user = User.create!(:person_id => person.id, :password => 'password')
      record = user.to_record
      assert_equal(user.id, record[:id])
      assert_equal(person.id, record[:person_id])
      assert_equal('password', record[:password])
      assert_equal('last', record[:person][:last])
      assert_equal('first', record[:person][:first])
    end
  end
  
  context "User with standard Person association" do
    setup do
      App.clean_all
      User.extjs_fields(:id, :password, :person)
    end
    should "produce a valid store config" do
      fields = User.extjs_record[:fields]
      assert_array_has_item(fields, 'has id') {|f| f[:name] === "id" }
      assert_array_has_item(fields, 'has person_id') {|f| f[:name] === "person_id" }
      assert_array_has_item(fields, 'has password') {|f| f[:name] === "password" }
      assert_array_has_item(fields, 'has person_last') {|f| f[:name] === "person_last" and f[:mapping] == "person.last" }
      assert_array_has_item(fields, 'has person_first') {|f| f[:name] === "person_first" and f[:mapping] == "person.first" }
    end
    should "produce a valid to_record record" do
      person = Person.create!(:first => 'first', :last => 'last', :email => 'email')
      user = User.create!(:person_id => person.id, :password => 'password')
      record = user.to_record
      assert_equal(user.id, record[:id])
      assert_equal(person.id, record[:person_id])
      assert_equal('password', record[:password])
      assert_equal('last', record[:person][:last])
      assert_equal('first', record[:person][:first])
    end
  end
  
  context "Person with User association (has_one relationship)" do
    setup do
      App.clean_all
      User.extjs_fields(:id, :password)
      Person.extjs_fields(:id, :user)
    end
    should "produce a valid store config" do
      fields = Person.extjs_record[:fields]
      assert_array_has_item(fields, 'has id') {|f| f[:name] === "id" }
      assert_array_has_item(fields, 'has user_id') {|f| f[:name] === "user_id" and f[:mapping] == 'user.id' }
      assert_array_has_item(fields, 'has user_password') {|f| f[:name] === "user_password"and f[:mapping] == 'user.password' }
    end
    should "produce a valid to_record record" do
      person = Person.create!(:first => 'first', :last => 'last', :email => 'email')
      user = User.create!(:person_id => person.id, :password => 'password')
      record = person.reload.to_record
      assert_equal(person.id, record[:id])
      assert_equal(user.id, record[:user][:id])
      assert_equal('password', record[:user][:password])
    end
  end
  
  context "Person with User association (has_one/belongs_to relationship) cyclic reference" do
    setup do
      App.clean_all
      User.extjs_fields(:id, :person)
      Person.extjs_fields(:id, :user)
    end
    should "produce a valid store config for Person" do
      fields = Person.extjs_record[:fields]
      assert_array_has_item(fields, 'has id') {|f| f[:name] === "id" }
      assert_array_has_item(fields, 'has user_id') {|f| f[:name] === "user_id" and f[:mapping] == 'user.id' }
    end
    should "produce a valid to_record record for Person" do
      person = Person.create!(:first => 'first', :last => 'last', :email => 'email')
      user = User.create!(:person_id => person.id, :password => 'password')
      record = person.reload.to_record
      assert_equal(person.id, record[:id])
      assert_equal(user.id, record[:user][:id])
    end
  end
  
  context "Fields should render with correct, ExtJS-compatible data-types" do
    setup do
      App.clean_all
      @fields = DataType.extjs_record[:fields]
    end
    
    should "Understand 'string'" do
      assert_array_has_item(@fields, 'has string_column with string') {|f| f[:name] == 'string_column' and f[:type] == 'string'}
    end
    should "Understand 'integer' as 'int'" do
      assert_array_has_item(@fields, 'has integer_column with int') {|f| f[:name] == 'integer_column' and f[:type] == 'int'}
    end
    should "Understand 'float'" do
      assert_array_has_item(@fields, 'has float_column with float') {|f| f[:name] == 'float_column' and f[:type] == 'float'}
    end
    should "Understand 'decimal' as 'float'" do # Is this correct??
      assert_array_has_item(@fields, 'has decimal_column with float') {|f| f[:name] == 'decimal_column' and f[:type] == 'float'}
    end
    should "Understand 'date'" do
      assert_array_has_item(@fields, 'has date_column with date') {|f| f[:name] == 'date_column' and f[:type] == 'date'}
    end
    should "Understand 'datetime' as 'date'" do
      assert_array_has_item(@fields, 'has datetime_column with date') {|f| f[:name] == 'datetime_column' and f[:type] == 'date'}
    end
    should "Understand 'time' as 'date'" do
      assert_array_has_item(@fields, 'has time_column with date') {|f| f[:name] == 'time_column' and f[:type] == 'date'}
    end
    should "Understand 'boolean'" do
      assert_array_has_item(@fields, 'has boolean_column with boolean') {|f| f[:name] == 'boolean_column' and f[:type] == 'boolean'}
    end
    should "Understand NOT NULL" do
      assert_array_has_item(@fields, 'has notnull_column with allowBlank == false') {|f| f[:name] == 'notnull_column' and f[:allowBlank] === false}
    end
    should "Understand DEFAULT" do
      assert_array_has_item(@fields, 'has default_column with defaultValue == true') {|f| f[:name] == 'default_column' and f[:defaultValue] === true}
    end
  end
  
  context "polymorphic associations" do
    setup do
      App.clean_all
    end
    
    should "return nil as class for a polymorphic relation" do
      assert_equal(nil, Address.extjs_associations[:addressable][:class])
    end
    
    should "create a proper default store config" do
      Address.extjs_fields
      fields = Address.extjs_record[:fields]
      assert_array_has_item(fields, 'has addressable_id') {|f| f[:name] === 'addressable_id' && !f[:mapping] }
      assert_array_has_item(fields, 'addressable_type') {|f| f[:name] === 'addressable_type' && !f[:mapping] }
    end
    
    should "create the right store config when including members of the polymorphic association" do
      Address.extjs_fields :street, :addressable => [:name]
      fields = Address.extjs_record[:fields]
      assert_array_has_item(fields, "has addressable_name") {|f| f[:name] === 'addressable_name' && f[:mapping] === 'addressable.name'}
      assert_array_has_item(fields, "has addressable_id") {|f| f[:name] === 'addressable_id' && !f[:mapping] }
      assert_array_has_item(fields, "has addressable_type") {|f| f[:name] === 'addressable_type' && !f[:mapping] }
    end
    
    should "fill in the right values for to_record" do
      Address.extjs_fields :street, :addressable => [:name]
      location = Location.create!(:name => 'Home')
      address = location.create_address(:street => 'Main Street 1')
      record = address.to_record
      assert_equal({:name => "Home", :id => location.id}, record[:addressable])
      assert_equal("Location", record[:addressable_type])
      assert_equal(location.id, record[:addressable_id])
      assert_equal(address.id, record[:id])
      assert_equal("Main Street 1", record[:street])
    end
  end
  
  context "single table inheritance" do
    setup do
      App.clean_all
    end
    
    should "fieldsets should be accessible from descendants" do
      Location.extjs_fieldset :on_location, [:street]
      fields = House.extjs_record(:on_location)[:fields]
      assert_array_has_item(fields, 'has street') {|f| f[:name] === 'street' }
      assert_array_has_not_item(fields, 'has name') {|f| f[:name] === 'name' }
    end
    should "fieldsets should be overrideable from descendants" do
      Location.extjs_fieldset :override, [:street]
      House.extjs_fieldset :override, [:name]
      fields = House.extjs_record(:override)[:fields]
      assert_array_has_not_item(fields, 'has street') {|f| f[:name] === 'street' }
      assert_array_has_item(fields, 'has name') {|f| f[:name] === 'name' }
    end
  end
  
  context "ExtJS::Model::Util" do
    context "#extract_fieldset_and_options default" do
      setup do
        @fieldset, @options = ExtJS::Model::Util.extract_fieldset_and_options [:fields => [:one, :two, :three]]
        @fields = @options[:fields]
      end
      should "return :default when no fieldset provided" do
        assert_equal(:'default', @fieldset)
      end
      should "not alter the fields array" do
        assert_equal([:one, :two, :three], @fields)
      end
    end

    context "#extract_fieldset_and_options with explicit fieldset definition and array with fields" do
      setup do
        @fieldset, @options = ExtJS::Model::Util.extract_fieldset_and_options [:explicit, [:one, :two, :three]]
        @fields = @options[:fields]
      end
      should "return :default when no fieldset provided" do
        assert_equal(:'explicit', @fieldset)
      end
      should "not alter the fields array" do
        assert_equal([:one, :two, :three], @fields)
      end
    end
    
    context "#extract_fieldset_and_options with explicit fieldset definition and hash with fields" do
      setup do
        @fieldset, @options = ExtJS::Model::Util.extract_fieldset_and_options [:explicit, {:fields => [:one, :two, :three]}]
        @fields = @options[:fields]
      end
      should "return :default when no fieldset provided" do
        assert_equal(:'explicit', @fieldset)
      end
      should "not alter the fields array" do
        assert_equal([:one, :two, :three], @fields)
      end
    end
    
    context "#extract_fieldset_and_options with only a hash" do
      setup do
        @fieldset, @options = ExtJS::Model::Util.extract_fieldset_and_options [{:fieldset => :explicit, :fields => [:one, :two, :three]}]
        @fields = @options[:fields]
      end
      should "return :default when no fieldset provided" do
        assert_equal(:'explicit', @fieldset)
      end
      should "not alter the fields array" do
        assert_equal([:one, :two, :three], @fields)
      end
    end
    
    context "#extract_fieldset_and_options edge cases" do
      should "called without arguments" do
        @fieldset, @options = ExtJS::Model::Util.extract_fieldset_and_options []
        @fields = @options[:fields]
        assert_equal(:'default', @fieldset)
        assert_equal([], @fields)
      end
      should "called with only the fieldset and no field arguments" do
        @fieldset, @options = ExtJS::Model::Util.extract_fieldset_and_options [:explicit]
        @fields = @options[:fields]
        assert_equal(:'explicit', @fieldset)
        assert_equal([], @fields)
      end
      should "raise error when called with more than 2 arguments" do
        assert_raise(ArgumentError) { ExtJS::Model::Util.extract_fieldset_and_options [:explicit, :some, {}] }
      end
      should "raise error when called with 2 arguments and the first one is no symbol" do
        assert_raise(ArgumentError) { ExtJS::Model::Util.extract_fieldset_and_options [{ :fields => [] }, :explicit] }
      end
    end
  end
  
  context "ExtJS::Model::ClassMethods" do
    
    context "#process_fields" do
      should "handle a simple Array of Symbols" do
        @fields = BogusModel.process_fields :one, :two, :three
        assert_equal([{:name => :one}, {:name => :two}, {:name => :three}], @fields)
      end
      should "handle a mixed Array where the last item is a Hash" do
        @fields = BogusModel.process_fields :one, :two, :three => [:three_one, :three_two]
        assert_equal([{:name => :one}, {:name => :two}, {:name => :three, :fields => [{:name => :three_one}, {:name => :three_two}]}], @fields)
      end
      should "handle a mixed Array where a middle item is a Hash" do
        @fields = BogusModel.process_fields :one, {:two => [:two_one, :two_two]}, :three
        assert_equal([
          {:name => :one}, 
          {:name => :two, :fields => [{:name => :two_one}, {:name => :two_two}]}, 
          {:name => :three}], @fields)
      end
      should "handle option :only" do
        @fields = BogusModel.process_fields :only => [:one, :two, :three]
        assert_equal([{:name => :one}, {:name => :two}, {:name => :three}], @fields)
      end
      should "handle option :exclude" do
        @fields = BogusModel.process_fields :exclude => [:two]
        assert_equal([{:name => :one}, {:name => :three_id}], @fields)
      end
      should "handle {:field => {:sortDir => 'ASC'}}" do
        @fields = BogusModel.process_fields({:field => {:sortDir => 'ASC'}})
        assert_equal([{:name => :field, :sortDir => 'ASC'}], @fields)
      end
      should "handle recursive definition" do
        @fields = BogusModel.process_fields(:one, {:three => [{:one => [:one, :two]}, {:two => {:sortDir => "ASC"}}]})
        assert_equal([{:name => :one}, {:name => :three, :fields => [{:name => :one, :fields => [{:name => :one}, {:name => :two}]}, {:name => :two, :sortDir => 'ASC'}]}], @fields)
      end
      should "not touch already correct fields" do
        @fields = BogusModel.process_fields(:one, {:name => :field,:sortDir => 'ASC'})
        assert_equal([{:name => :one},{:name => :field, :sortDir => 'ASC'}], @fields)
      end
      should "raise ArgumentError when pass in bogus hash" do
        assert_raise(ArgumentError) { @fields = BogusModel.process_fields(:one, {:nme => :field,:sortDir => 'ASC'}) }
      end
    end
    
    context "#extjs_field" do
      should "type gets set to 'auto' when not present" do
        @field = BogusModel.extjs_field({:name => :test})
        assert_equal('auto', @field[:type])
      end
      should "not touch type when alredy present" do
        @field = BogusModel.extjs_field({:name => :test, :type => 'untouched'})
        assert_equal('untouched', @field[:type])
      end
      should "raise exception when bogus field config passed" do
        assert_raise(ArgumentError) { BogusModel.extjs_field({:name => :test, "type" => 'untouched'}) }
      end

    end
    
    context "#extjs_field with ORM config" do
      should "set allowBlank" do
        BogusModel.expects(:extjs_allow_blank).returns(false)
        @field = BogusModel.extjs_field({:name => :test}, stub())
        assert_equal(false, @field[:allowBlank])
      end
      should "set type" do
        BogusModel.expects(:extjs_type).returns('int')
        @field = BogusModel.extjs_field({:name => :test}, stub())
        assert_equal('int', @field[:type])
      end
      should "set defaultValue" do
        BogusModel.expects(:extjs_default).returns(true)
        @field = BogusModel.extjs_field({:name => :test}, stub())
        assert_equal(true, @field[:defaultValue])
      end
      should "set dateFormat to c it's a date" do
        BogusModel.expects(:extjs_type).returns('date')
        @field = BogusModel.extjs_field({:name => :test}, stub())
        assert_equal('c', @field[:dateFormat])
      end
      should "not touch dateFormat if it's already set" do
        BogusModel.expects(:extjs_type).returns('date')
        @field = BogusModel.extjs_field({:name => :test, :dateFormat => 'not-c'}, stub())
        assert_equal('not-c', @field[:dateFormat])
      end
    end
    
    context "#extjs_field with Hash config" do
      should "set correct name and mapping" do
        @field = BogusModel.extjs_field({:name => :son}, {:mapping => 'grandfather.father', :parent_trail => 'grandfather_father'})
        assert_equal('grandfather_father_son', @field[:name])
        assert_equal('grandfather.father.son', @field[:mapping])
      end
      should "apply config to field" do
        @field = BogusModel.extjs_field({:name => :son}, {:sortDir => 'ASC'})
        assert_equal('ASC', @field[:sortDir])
      end
    end
    
    context "#extjs_get_fields_for_fieldset" do
      should "return full list of columns for fieldset that was not defined, yet" do
        @fields = BogusModel.extjs_get_fields_for_fieldset :not_there
        assert_equal(BogusModel.process_fields(*BogusModel.extjs_column_names), @fields)
      end
      should "return the right fields for a fieldset that was defined before in the same class" do
        BogusModel.extjs_fieldset :fieldset_was_defined, [:one]
        @fields = BogusModel.extjs_get_fields_for_fieldset :fieldset_was_defined
        assert_equal(BogusModel.process_fields(:one), @fields)
      end
      should "return the fieldset of the ancestor when it was only defined in the ancestor" do
        BogusModel.extjs_fieldset :fieldset_was_defined_in_ancestor, [:one]
        @fields = BogusModelChild.extjs_get_fields_for_fieldset :fieldset_was_defined_in_ancestor
        assert_equal(BogusModel.process_fields(:one), @fields)
      end
      should "return the fieldset of the child when it was defined in the child and the ancestor" do
        BogusModel.extjs_fieldset :fieldset_was_defined_in_both, [:one]
        BogusModelChild.extjs_fieldset :fieldset_was_defined_in_both, [:two]
        @fields = BogusModelChild.extjs_get_fields_for_fieldset :fieldset_was_defined_in_both
        assert_equal(BogusModel.process_fields(:two), @fields)
      end
    end
  end

  protected
  def assert_array_has_item array, item_description, &blk
    assert array.find {|i| blk.call(i) }, "The array #{array.inspect} should #{item_description} but it does not"
  end
  def assert_array_has_not_item array, item_description, &blk
    assert !array.find {|i| blk.call(i) }, "The array #{array.inspect} should not #{item_description} but it does"
  end
  
end

