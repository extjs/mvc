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
      
      ##
      # Converts a model instance to a record compatible with ExtJS
      # @params {Mixed} params A list of fields to use instead of this Class's extjs_record_fields
      #
      def to_record(*params)
        
        fields = (params.empty?) ? self.class.extjs_record_fields : self.class.process_fields(*params)
        pk = self.class.extjs_primary_key
        assns = self.class.extjs_associations
      
        data = {pk => self.send(pk)}  
        fields.each do |field|
          if refl = assns[field[:name]]
            if refl[:type] === :belongs_to
              assn = self.send(field[:name])
              if assn.respond_to?(:to_record)
                data[field[:name]] = assn.send(:to_record, *field[:fields])
              elsif (field[:fields])
                data[field[:name]] = {}
                field[:fields].each do |property|
                  data[field[:name]][property] = assn.send(property)
                end
              else
                data[field[:name]] = {} # belongs_to assn that doesn't respond to to_record and no fields list
              end
            elsif refl[:type] === :many
              data[field[:name]] = self.send(field[:name]).collect {|r| r.to_record}  #CAREFUL!!!!!!!!!!!!1
            end
          else
            value = self.send(field[:name])
            data[field[:name]] = value.respond_to?(:to_record) ? value.to_record : value
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
      def extjs_record(*fields)
        if self.extjs_record_fields.empty?
          self.extjs_fields(*self.extjs_column_names)
        end
        
        fields = fields.empty? ? self.extjs_record_fields : self.process_fields(*fields)
        
        pk = self.extjs_primary_key
        columns = self.extjs_columns_hash
        associations = self.extjs_associations
        
        rs = []
        fields.each do |field|
          field = field.dup
          if columns[field[:name]] || columns[field[:name].to_s]  # <-- column on this model                
            rs << self.extjs_field(field, columns[field[:name]] || columns[field[:name].to_s])      
          elsif assn = associations[field[:name] || field[:name].to_s]
            assn_fields = field.delete(:fields) || []
            if assn[:class].respond_to?(:extjs_record)  # <-- exec extjs_record on assn Model.
              rs.concat(assn[:class].send(:extjs_record, *assn_fields)["fields"].collect {|assn_field| 
                extjs_field(assn_field, :mapping => field[:name])
              })
            elsif assn_fields.length > 0  # <-- :parent => [:id, :name]
              rs.concat(assn_fields.collect {|assn_field| 
                extjs_field(assn_field, :mapping => field[:name])
              })
            else  
              rs << extjs_field(field)
            end
          else # property is a method?
            rs << extjs_field(field)
          end
        end
        
        return {
          "fields" => rs,
          "idProperty" => pk
        }
      end
      
      ##
      # meant to be used within a Model to define the extjs record fields.
      # eg:
      # class User
      #   extjs_fields :first, :last, :email => {"sortDir" => "ASC"}, :company => [:id, :name]
      # end
      #
      def extjs_fields(*params)
        self.extjs_record_fields = self.process_fields(*params)
      end
      
      ##
      # Prepare a field configuration list into a normalized array of Hashes, {:name => "field_name"} 
      # @param {Mixed} params
      # @return Array
      #
      def process_fields(*params) 
        params = [] if params.first.nil?
        options = params.extract_options!
        
        fields = []
        if !options.keys.empty?
          if excludes = options.delete(:exclude)
            fields = self.create_fields(self.extjs_column_names.reject {|c| excludes.find {|ex| c === ex.to_s}}.collect {|c| c})
          elsif only = options.delete(:only)
            fields = self.create_fields(only)
          else
            options.keys.each do |k|  # <-- :email => {"sortDir" => "ASC"}
              if options[k].is_a? Hash
                options[k][:name] = k.to_sym
                fields << options[k]
              elsif options[k].is_a? Array # <-- :parent => [:id, :name]
                fields << {
                  :name => k.to_sym,
                  :fields => options[k]
                }
              end
            end
          end
          #self.extjs_record_fields.concat(process_association_fields(options))
        elsif params.empty?
          return self.extjs_record_fields
        end
        
        unless params.empty?
          fields.concat(params.collect {|f|
            {:name => f.to_sym}
          })
        end
        fields
      end
      
      ##
      # Render a column-config object
      # @param {Hash/Column} field Field-configuration Hash, probably has :name already set and possibly Ext.data.Field options.
      # @param {ORM Column Object from AR, DM or MM}
      #
      def extjs_field(field, config=nil)  
        if config.kind_of? Hash
          if mapping = config.delete(:mapping)
            field.update(
              :name => "#{mapping}_#{field[:name]}",
              "mapping" => "#{mapping}.#{field[:name]}"
            )
          end
          field.update(config) unless config.keys.empty?
        elsif !config.nil?  # <-- Hopfully an ORM Column object.
          field.update(
            "allowBlank" => self.extjs_allow_blank(config),
            "type" => self.extjs_type(config)
          )
          field["dateFormat"] = "c" if field["type"] === :date  # <-- ugly hack for date  
        end  
        field.update("type" => "auto") if field["type"].nil?
        field
      end

private
      
      ##
      # Prepare the config for fields with '.' in their names
      #
      def process_association_fields(options)
        results = []
        options.each do |assoc, fields|
          fields.each do |field|
            results << [assoc, field]
          end
        end
        results
      end

      ##
      # Returns an array of symbolized association names that will be referenced by a call to to_record
      # i.e. [:parent1, :parent2]
      #
      def extjs_used_associations
        if @extjs_used_associations.nil?
          assoc = []
          self.extjs_record_fields.each do |f|
            #This needs to be the first condition because the others will break if f is an Array
            if f.is_a? Array
              assoc << f.first
            elsif extjs_associations[f]
              assoc << f
            end
          end
          @extjs_used_associations = assoc.uniq
        end
        @extjs_used_associations
      end
    end
  end
end

