module ExtJS
  module Model
    def self.included(model)
      model.send(:extend, ClassMethods)
      model.send(:include, InstanceMethods)
    end

    ##
    # InstanceMethods
    #
    module InstanceMethods
      def to_record
        data = {self.class.primary_key => self.send(self.class.primary_key)}
        self.class.extjs_fields.each do |f|
          data[f] = self.send(f)
        end
        data
      end
    end
    ##
    # ClassMethods
    #
    module ClassMethods
      @@fields = []
      ##
      # Defines the subset of AR columns used to create Ext.data.Record def'n.
      # @param {Array/Hash} list-of-fields to include, :only, or :exclude
      #
      def extjs_fields(*params)
        options = params.extract_options!
        if !options.keys.empty?
          if options[:only]
            @@fields = options[:only]
          elsif options[:exclude]
            @@fields = self.columns.reject {|c| options[:exclude].find {|ex| c.name.to_sym === ex}}.collect {|c| c.name.to_sym}
          end
        elsif !params.empty?
          @@fields = params
        else
          @@fields
        end
      end

      ##
      # render AR columns to Ext.data.Record.create format
      # eg: {name:'foo', type: 'string'}
      #
      def extjs_record
        @@fields = self.columns.collect {|c| c.name.to_sym } if @@fields.empty?
        {
          "fields" => @@fields.collect {|f|
            col = self.columns.find {|c| c.name.to_sym === f}
            type = col.type
            case col.type
              when :datetime || :date || :time || :timestamp
                type = :date
              when :text
                type = :string
              when :integer
                type = :int
            end
            field = {:name => col.name, :allowBlank => col.null, :type => type}
            field[:dateFormat] = "c" if col.type === :datetime || col.type === :date  # <-- ugly hack for date
            field
          },
          "idProperty" => self.primary_key
        }
      end
    end
  end
end

