class Test::Unit::TestCase
    ##
    # Asserts that the passed list of fields are specified in the extjs_fields call
    # in the model class.
    # @fields {Symbols} fields A list of fields
    #
  def self.should_have_extjs_fields *fields
    klass = described_type
    should "have the correct extjs_fields" do
      fields.each do |field|
        found_record = klass.extjs_record_fields.find do|record_field|
          record_field[:name] == field.to_s
        end
        assert_not_nil found_record, "extjs field #{field} isn't listed in the #{klass.name} model"
      end
    end
  end
end
