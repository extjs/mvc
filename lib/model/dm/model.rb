module ExtJS
  module Model
    def self.included(model)
      model.send(:extend, ClassMethods)
      model.send(:include, InstanceMethods)
      model.class_eval do
        cattr_accessor :extjs_record_fields
      end
      model.extjs_record_fields = []
    end

    ##
    # InstanceMethods
    #
    module InstanceMethods
      def to_record
        properties = self.class.properties
        pk = self.class.key.first.name

        data = {pk => self.send(pk)}
        self.class.extjs_record_fields.each do |f|
          if refl = self.class.relationships[f]
            if refl.options[:max].nil? && refl.options[:min].nil? # belongs_to
              assn = self.send(f)
              data[f] = (assn) ? assn.to_record : {} # <-- a thing was requested, give emtpy thing.
            elsif refl.options[:max] > 1
              #data[f] = self.send(f).collect {|r| r.to_record}  CAREFUL!!!!!!!!!!!!1
            end
          else
            data[f] = self.send(f)
          end
        end
        data
      end
    end
    ##
    # ClassMethods
    #
    module ClassMethods
      ##
      # Defines the subset of AR columns used to create Ext.data.Record def'n.
      # @param {Array/Hash} list-of-fields to include, :only, or :exclude
      #
      def extjs_fields(*params)
        options = params.extract_options!
        if !options.keys.empty?
          if options[:exclude]
            self.extjs_record_fields = self.properties.reject {|p| options[:exclude].find {|ex| p.name === ex}}.collect {|p| p.name}
          end
        elsif !params.empty?
          self.extjs_record_fields = params
        else
          self.extjs_record_fields
        end
      end

      ##
      # render AR columns to Ext.data.Record.create format
      # eg: {name:'foo', type: 'string'}
      #
      def extjs_record
        if self.extjs_record_fields.empty?
          self.extjs_record_fields = self.properties.collect {|p| p.name}
        end

        pk = self.key.first

        return {
          "fields" => self.extjs_record_fields.collect {|f|
            if self.properties.has_property?(f)
              col = self.properties[f]
              type = ((col.type.respond_to?(:primitive)) ? col.type.primitive : col.type).to_s
              case type
                when "DateTime" || "Date" || "Time"
                  type = :date
                when "String"
                  type = :string
                when "Float"
                  type = :float
                when "Integer" || "BigDecimal"
                  type = :int
              end
              field = {:name => col.name, :allowBlank => (col === pk) ? true : col.nullable?, :type => type}
              field[:dateFormat] = "c" if type === :date  # <-- ugly hack for date
              field
            elsif assn = self.relationships[f]
              field = {:name => f, :allowBlank => true, :type => 'auto'}
            end
          },
          "idProperty" => pk.name
        }
      end
    end
  end
end

