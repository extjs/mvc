##
# MongoMapper adapter to ExtJS::Model mixin
#
module ExtJS
  module Model
    ##
    # ClassMethods
    #
    module ClassMethods

      def extjs_primary_key
        :_id
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
            @extjs_associations[key.to_sym] = {
              :name => key,
              :type => self.associations[key].type,
              :class => self.associations[key].class_name.constantize,
              :foreign_key => self.associations[key].foreign_key,
              :is_polymorphic => false # <-- no impl. for MM is_polymorhpic yet.  Anyone care to implement this?
            }
          end
        end
        @extjs_associations
      end

      def extjs_type(col)
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
      end

      def extjs_allow_blank(col)
        (col.name == '_id') || (col.options[:required] != true)
      end
      
      def extjs_default(col)
        col.default_value
      end
      
    end
  end
end

