module ExtJS
  module Model
    
    def self.included(model)
      model.send(:extend, ClassMethods)
      model.send(:include, InstanceMethods)
      model.class_eval do
        ##
        # @config {Array} List of DataReader fields to render.  This should probably not be a cattr_accessor
        # since it's only used internally.  The user adds fields via the Class method extjs_fields instead.
        #
        cattr_accessor :extjs_record_fields
        ##
        # @config {String} extjs_mapping_template This a template used to render mapped field-names.
        # One could use the Rails standard "{association}[{property}]" as well.
        #
        cattr_accessor :extjs_mapping_template
      end
      model.extjs_record_fields = []
      model.extjs_mapping_template = "_{property}"
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
        if self.class.extjs_record_fields.empty?
          self.class.extjs_fields(*self.class.extjs_column_names)
        end
        
        fields  = (params.empty?) ? self.class.extjs_record_fields : self.class.process_fields(*params)
        assns   = self.class.extjs_associations
        pk      = self.class.extjs_primary_key
        
        # build the initial field data-hash
        data    = {pk.to_s => self.send(pk)}
         
        fields.each do |field|
          if refl = assns[field[:name]] || assns[field[:name].to_sym]
            if refl[:type] === :belongs_to
              assn = self.send(field[:name])
              
              if assn.respond_to?(:to_record)
                data[field[:name]] = assn.to_record field[:fields]
              elsif (field[:fields])
                data[field[:name]] = {}
                field[:fields].each do |property|
                  data[field[:name]][property] = assn.send(property) if assn.respond_to?(property)
                end
              else
                data[field[:name]] = {} # belongs_to assn that doesn't respond to to_record and no fields list
              end
              # Append associations foreign_key to data
              data[refl[:foreign_key].to_s] = self.send(refl[:foreign_key])
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
        
        associations  = self.extjs_associations
        columns       = self.extjs_columns_hash
        fields        = fields.empty? ? self.extjs_record_fields : self.process_fields(*fields)  
        pk            = self.extjs_primary_key
        rs            = []
        
        fields.each do |field|
          field = field.dup
          
          if col = columns[field[:name]] || columns[field[:name].to_sym]  # <-- column on this model                
            rs << self.extjs_field(field, col)      
          elsif assn = associations[field[:name]] || associations[field[:name].to_sym]
            assn_fields = field.delete(:fields) || nil
            if assn[:class].respond_to?(:extjs_record)  # <-- exec extjs_record on assn Model.
              record = assn[:class].extjs_record(assn_fields)
              rs.concat(record["fields"].collect {|assn_field| 
                extjs_field(assn_field, :mapping => field[:name])
              })
            elsif assn_fields  # <-- :parent => [:id, :name]
              rs.concat(assn_fields.collect {|assn_field| 
                extjs_field(assn_field, :mapping => field[:name])
              })
            else  
              rs << extjs_field(field)
            end
            
            # attach association's foreign_key if not already included.
            if (col = columns[assn[:foreign_key]] || columns[assn[:foreign_key].to_s]) && !rs.include?({:name => assn[:foreign_key].to_s})
              rs << extjs_field({:name => assn[:foreign_key]}, col)
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
        
        # Return immediately if pre-processed fields are detected.
        # ie: [ [{:name => 'foo'}, {:name => 'bar'}] ]
        # This is to handle the case where extjs_record and to_record are called recursively, in which case
        # these fields have already been processed.
        #
        #if params.length === 1 && params.first.kind_of?(Array) && !params.first.empty?
        #  return params.first
        #end
        
        fields = []
        if !options.keys.empty?
          if excludes = options.delete(:exclude)
            fields = self.process_fields(self.extjs_column_names.reject {|c| excludes.find {|ex| c === ex.to_s}}.collect {|c| c})
          elsif only = options.delete(:only)
            fields = self.process_fields(only)
          else
            options.keys.each do |k|  # <-- :email => {"sortDir" => "ASC"}
              if options[k].is_a? Hash
                options[k][:name] = k.to_s
                fields << options[k]
              elsif options[k].is_a? Array # <-- :parent => [:id, :name]
                fields << {
                  :name => k.to_s,
                  :fields => process_fields(*options[k])
                }
              end
            end
          end
        elsif params.empty?
          return self.extjs_record_fields
        end
        
        unless params.empty?
          params = params.first if params.length == 1 && params.first.kind_of?(Array) && !params.first.empty?
          params.each do |f|
            if f.kind_of?(Hash)
              fields << f
            else
              fields << {:name => f.to_s}
            end
          end
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
            field.update( # <-- We use a template for rendering mapped field-names.
              :name => mapping + self.extjs_mapping_template.gsub(/\{property\}/, field[:name]),
              "mapping" => "#{mapping.to_s}.#{field[:name]}"
            )
          end
          field.update(config) unless config.keys.empty?
        elsif !config.nil?  # <-- Hopfully an ORM Column object.
          field.update(
            "allowBlank" => self.extjs_allow_blank(config),
            "type" => self.extjs_type(config)
          )
          field["dateFormat"] = "c" if field["type"] === :date && field["dateFormat"].nil? # <-- ugly hack for date  
        end  
        field.update("type" => "auto") if field["type"].nil?
        field
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
            if extjs_associations[f[:name]]
              assoc << f[:name]
            end
          end
          @extjs_used_associations = assoc.uniq
        end
        @extjs_used_associations
      end
    end
  end
end

