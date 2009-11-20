##
# DataMapper adapter for ExtJS::Model mixin
#
module ExtJS
  module Model
    module ClassMethods
      
      def extjs_primary_key
        self.key.first.name
      end
      
      def extjs_column_names
        self.properties.collect {|p| p.name.to_s }
      end
      
      def extjs_columns_hash
        if @extjs_columns_hash.nil?
          @extjs_columns_hash = {}
          self.properties.each do |p|
            @extjs_columns_hash[p.name] = p
          end
        end
        @extjs_columns_hash
      end
      
      def extjs_allow_blank(col)
         (col === pk) ? true : col.nullable?
      end
      
      def extjs_type(col)
        type = ((col.type.respond_to?(:primitive)) ? col.type.primitive : col.type).to_s
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
      
      def extjs_associations
        if @extjs_associations.nil?  
          @extjs_associations = {}
          self.relationships.keys.each do |key|
            assn = self.relationships[key]
            type = (assn.options[:max].nil? && assn.options[:min].nil?) ? :belongs_to : (assn.options[:max] > 1) ? :many : nil 
            @extjs_associations[key.to_sym] = {:name => key, :type => type}
          end
        end
        @extjs_associations
      end
    end
  end
end

