##
# ActiveRecord adapter to ExtJS::Model mixin.
#
module ExtJS
  module Model
    module ClassMethods
      
      def extjs_primary_key
        self.primary_key.to_sym
      end
      
      def extjs_column_names
        self.column_names
      end
      
      def extjs_columns_hash
        self.columns_hash
      end
      
      ##
      # determine if supplied Column object is nullable
      # @param {ActiveRecord::ConnectionAdapters::Column}
      # @return {Boolean}
      #
      def extjs_allow_blank(col)
        col.null
      end
      
      ##
      # determine datatype of supplied Column object
      # @param {ActiveRecord::ConnectionAdapters::Column}
      # @return {Symbol}
      #
      def extjs_type(col)
        type = col.type
        case type
          when :datetime, :date, :time, :timestamp
            type = :date
          when :text
            type = :string
          when :integer
            type = :int
          when :decimal
            type = :float
        end
        type
      end
      
      ##
      # return a simple, normalized list of AR associations having the :name, :type and association class
      # @return {Array}
      #
      def extjs_associations
        if @extjs_associations.nil?
          @extjs_associations = {}
          self.reflections.keys.each do |key|
            assn = self.reflections[key]
            type = (assn.macro === :has_many) ? :many : assn.macro
            @extjs_associations[key.to_sym] = {
              :name => key, 
              :type => type, 
              :class => assn.class_name.constantize,
              :foreign_key => assn.association_foreign_key
            }
          end
        end        
        @extjs_associations
      end
    end
  end
end

