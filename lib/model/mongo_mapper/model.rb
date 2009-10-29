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
        properties = self.class.column_names
        pk = "id"
        
        data = {pk => self.send(pk)}
        self.class.extjs_record_fields.each do |f|
          if refl = self.class.associations[f]
            if refl.type === :belongs_to
              assn = self.send(f)
              data[f] = (assn) ? assn.to_record : {} # <-- a thing was requested, give emtpy thing.
            elsif refl.type === :many
              data[f] = self.send(f).collect {|r| r.to_record}  #CAREFUL!!!!!!!!!!!!1
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
            self.extjs_record_fields = self.column_names.reject {|p| options[:exclude].find {|ex| p === ex.to_s}}.collect {|p| p}
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
          self.extjs_record_fields = self.column_names
        end

        pk = "_id"

        return {
          "fields" => self.extjs_record_fields.collect {|f|
            if self.keys[f]
            
              col = self.keys[f]
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
              field = {:name => col.name, :allowBlank => (col.name === pk) ? true : col.options[:required] === true, :type => type}
              field[:dateFormat] = "c" if type === :date  # <-- ugly hack for date
              field
            elsif assn = self.associations[f.to_sym]
              field = {:name => f, :allowBlank => true, :type => 'auto'}
            else # property is a method?
              field = {:name => f, :allowBlank => true, :type => 'auto'}
            end
          },
          "idProperty" => "id"
        }
      end
    end
  end
end

