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
        :id
      end

      def extjs_column_names
        self.column_names
      end

      def extjs_columns_hash
        self.keys
      end

      def extjs_associations
        @extjs_associations ||= self.associations.inject({}) do |memo, (key, assn)|
          memo[key.to_sym] = {
            :name => key.to_sym,
            :type => assn.type,
            :class => assn.class_name.constantize,
            :foreign_key => assn.foreign_key,
            :is_polymorphic => false
          }
          memo
        end
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

