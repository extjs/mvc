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
        pk = self.class.get_primary_key
        assns = self.class.get_associations
        
        data = {pk => self.send(pk)}
        self.class.extjs_record_fields.each do |f|
          if refl = assns[f]
            if refl[:type] === :belongs_to
              assn = self.send(f)
              data[f] = (assn) ? assn.to_record : {} # <-- a thing was requested, give emtpy thing.
            elsif refl[:type] === :many
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
      # render AR columns to Ext.data.Record.create format
      # eg: {name:'foo', type: 'string'}
      #
      def extjs_record
        
        if self.extjs_record_fields.empty?
          self.extjs_record_fields = self.get_column_names
        end

        pk = self.get_primary_key
        columns = self.get_columns
        associations = self.get_associations
        
        return {
          "fields" => self.extjs_record_fields.collect {|f|
            if columns[f.to_sym]
              col = columns[f.to_sym]
              field = {:name => col[:name], :allowBlank => col[:required] === false, :type => col[:type]}
              field[:dateFormat] = "c" if col[:type] === :date  # <-- ugly hack for date
              field
            elsif assn = associations[f]
              field = {:name => f, :allowBlank => true, :type => 'object'}
            else # property is a method?
              field = {:name => f, :allowBlank => true, :type => 'auto'}
            end
          },
          "idProperty" => pk
        }
      end
      
      ##
      # Defines the subset of AR columns used to create Ext.data.Record def'n.
      # @param {Array/Hash} list-of-fields to include, :only, or :exclude
      #
      def extjs_fields(*params)
        options = params.extract_options!
        if !options.keys.empty?
          if options[:exclude]
            self.extjs_record_fields = self.get_column_names.reject {|p| options[:exclude].find {|ex| p === ex.to_s}}.collect {|p| p}
          end
        elsif !params.empty?
          self.extjs_record_fields = params
        else
          self.extjs_record_fields
        end
      end
    end
  end
end

