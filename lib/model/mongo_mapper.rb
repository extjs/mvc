module ExtJS
  module Model
    ##
    # ClassMethods
    #
    module ClassMethods
      
      def extjs_primary_key
        "id"
      end
      
      def extjs_column_names
        self.column_names
      end
      
      def extjs_columns_hash
        self.keys
      end
      
      def extjs_associations
        if @extjs_associations.nil?
          @extjs_associations = {}
          self.associations.keys.each do |key|
            @extjs_associations[key.to_sym] = {:name => key, :type => self.associations[key].type}
          end
        end
        @extjs_associations
      end
      
      def extjs_render_column(col)
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
        {:name => col.name, :type => type, :allowBlank => (col.name === '_id') ? true : (col.options[:required] === true) ? false : true }
      end
    end
  end
end

