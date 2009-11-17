module ExtJS
  module Model
    
    module ClassMethods
      
      def get_primary_key
        self.key.first.name
      end
      
      def get_column_names
        self.properties.collect {|p| p.name.to_s }
      end
      
      def get_columns
        if @columns.nil?
          @columns = {}
          pk = self.key.first
          self.properties.each do |col|
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
          columns[col.name.to_sym] = {:name => col.name.to_s, :type => type, :required => (col === pk || !col.nullable?) ? true : false }
        end
        @columns
      end
      
      def get_associations
        assns = {}
        self.relationships.keys.each do |key|
          assn = self.relationships[key]
          type = (assn.options[:max].nil? && assn.options[:min].nil?) ? :belongs_to : (assn.options[:max] > 1) ? :many : nil 
          assns[key.to_sym] = {:name => key, :type => type}
        end
        assns
      end
    end
  end
end

