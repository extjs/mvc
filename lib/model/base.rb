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
        pk = self.class.extjs_primary_key
        assns = self.class.extjs_associations
        
        data = {pk => self.send(pk)}
        self.class.extjs_record_fields.each do |f|
          if refl = assns[f]
            if refl[:type] === :belongs_to
              assn = self.send(f)
              data[f] = (assn) ? assn.to_record : {} # <-- a thing was requested, give emtpy thing.
            elsif refl[:type] === :many
              data[f] = self.send(f).collect {|r| r.to_record}  #CAREFUL!!!!!!!!!!!!1
            end
          elsif f.is_a? Array
            value = self
            f.each do |method|
              value = value.send(method)
              break if value.nil?
            end
            data[f.join('__')] = value
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
          self.extjs_record_fields = self.extjs_column_names
        end

        pk = self.extjs_primary_key
        columns = self.extjs_columns_hash
        associations = self.extjs_associations
        
        return {
          "fields" => self.extjs_record_fields.collect {|f|
            #This needs to be the first condition because the others will break if f is an Array
            if f.is_a? Array
              field = {:name => f.join('__'), :type => 'auto'}
            elsif columns[f.to_sym] || columns[f.to_s]
              field = self.extjs_render_column(columns[f.to_sym] || columns[f.to_s])
              field[:dateFormat] = "c" if field[:type] === :date  # <-- ugly hack for date
              field
            elsif assn = associations[f]
              field = {:name => f, :allowBlank => true, :type => 'auto'}
            else # property is a method?
              field = {:name => f, :allowBlank => true, :type => 'auto'}
            end
          },
          "idProperty" => pk
        }
      end
      
      def extjs_fields(*params)
        options = params.extract_options!
        if !options.keys.empty?
          if excludes = options.delete(:exclude)
            self.extjs_record_fields = self.extjs_column_names.reject {|c| excludes.find {|ex| c === ex.to_s}}.collect {|c| c}
          elsif only = options.delete(:only)
            self.extjs_record_fields = only
          end
          self.extjs_record_fields.concat(process_association_fields(options))
        elsif params.empty?
          return self.extjs_record_fields
        end

        self.extjs_record_fields.concat(params) if !params.empty?

        #Append primary key if it's not included
        # I don't think we want to automatically include :id
        # Chris
        #self.extjs_record_fields << self.primary_key.to_sym if !self.extjs_record_fields.include?(self.primary_key.to_sym)
      end
      
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
    end
  end
end

