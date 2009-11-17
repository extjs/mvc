module ExtJS
  module Model
    ##
    # ClassMethods
    #
    module ClassMethods
      
      def get_primary_key
        "id"
      end
      
      def get_column_names
        self.column_names
      end
      
      def get_associations
        assns = {}
        self.associations.keys.each do |key|
          assns[key.to_sym] = {:name => key, :type => self.associations[key].type}
        end
        assns
      end
      
      def get_columns
        columns = {}
        self.column_names.each do |name|
          col = self.keys[name]
          type = col.type.to_s
          case type
            when "DateTime", "Date", "Time"
              type = :date
            when "String"
              type = :string
            when "Float"
              type = :float
            when "Integer", "BigDecimal"
              type = :int
            else
              type = "auto"
          end 
          columns[name.to_sym] = {:name => name, :type => type, :required => (col.options[:required] === true || name === "_id") ? true : false }
        end
        columns
      end
    end
  end
end

