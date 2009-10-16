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
        data = {self.class.primary_key => self.send(self.class.primary_key)}
        self.class.extjs_record_fields.each do |f|
          if refl = self.class.reflections[f]
            if refl.macro === :belongs_to
	      assn = self.send(f)
              data[f] = (assn) ? assn.to_record : {} # <-- a thing was requested, give emtpy thing.
            elsif refl.macro === :has_many
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
            self.extjs_record_fields = self.columns.reject {|c| options[:exclude].find {|ex| c.name.to_sym === ex}}.collect {|c| c.name.to_sym}
          elsif options[:only]
            self.extjs_record_fields = options[:only].reject {|c| !self.columns.find {|col| col.name.to_sym === c}}
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
          self.extjs_record_fields = self.columns.collect {|c| c.name.to_sym }
          self.extjs_record_fields.concat(self.reflect_on_all_associations.collect {|assn| assn.name})
        end

        return {
          "fields" => self.extjs_record_fields.collect {|f|
            if col = self.columns_hash[f.to_s]
              type = col.type
              case col.type
                when :datetime || :date || :time || :timestamp
                  type = :date
                when :text
                  type = :string
                when :integer
                  type = :int
                when :decimal
                  type = :float
              end
              field = {:name => col.name, :allowBlank => (col.primary) ? true : col.null, :type => type}
              field[:dateFormat] = "c" if col.type === :datetime || col.type === :date  # <-- ugly hack for date
              field
            elsif self.reflections[f]
              assn = self.reflections[f]
              field = {:name => assn.name, :allowBlank => true, :type => 'auto'}
            end
          },
          "idProperty" => self.primary_key
        }
      end
    end
  end
end

