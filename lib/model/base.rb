module ExtJS
  module Model

    def self.included(model)
      model.send(:extend, ClassMethods)
      model.send(:include, InstanceMethods)
      ##
      # @config {String} extjs_parent_trail_template This a template used to render mapped field-names.
      # Default is Proc.new{ |field_name| "_#{field_name}" }
      # You could also use the Rails standard
      # Proc.new{ |field_name| "[#{field_name}]" }
      #
      model.cattr_accessor :extjs_parent_trail_template
      model.extjs_parent_trail_template = Proc.new{ |field_name| "_#{field_name}" } if model.extjs_parent_trail_template.nil?
    end

    ##
    # InstanceMethods
    #
    module InstanceMethods

      ##
      # Converts a model instance to a record compatible with ExtJS
      #
      # The first parameter should be the fieldset for which the record will be returned.
      # If no parameter is provided, then the default fieldset will be choosen
      # Alternativly the first parameter can be a Hash with a :fields member to directly specify
      # the fields to use for the record.
      #
      # All these are valid calls:
      #
      #  user.to_record             # returns record for :default fieldset
      #                             # (fieldset is autmatically defined, if not set)
      #
      #  user.to_record :fieldset   # returns record for :fieldset fieldset
      #                             # (fieldset is autmatically defined, if not set)
      #
      #  user.to_record :fields => [:id, :password]
      #                             # returns record for the fields 'id' and 'password'
      #
      # For even more valid options for this method (which all should not be neccessary to use)
      # have a look at ExtJS::Model::Util.extract_fieldset_and_options
      def to_record(*params)
        fieldset, options = Util.extract_fieldset_and_options params

        fields = []
        if options[:fields].empty?
          fields = self.class.extjs_get_fields_for_fieldset(fieldset)
        else
          fields = self.class.process_fields(*options[:fields])
        end

        assns   = self.class.extjs_associations
        pk      = self.class.extjs_primary_key

        # build the initial field data-hash
        data    = {pk => self.send(pk)}

        fields.each do |field|
          next if data.has_key? field[:name] # already processed (e.g. explicit mentioning of :id)

          value = nil
          if association_reflection = assns[field[:name]] # if field is an association
            association = self.send(field[:name])

            # skip this association if we already visited it
            # otherwise we could end up in a cyclic reference
            next if options[:visited_classes].include? association.class

            case association_reflection[:type]
            when :belongs_to, :has_one
              if association.respond_to? :to_record
                assn_fields = field[:fields]
                if assn_fields.nil?
                  assn_fields = association.class.extjs_get_fields_for_fieldset(field.fetch(:fieldset, fieldset))
                end

                value = association.to_record :fields => assn_fields,
                  :visited_classes => options[:visited_classes] + [self.class]
              else
                value = {}
                (field[:fields]||[]).each do |sub_field|
                  value[sub_field[:name]] = association.send(sub_field[:name]) if association.respond_to? sub_field[:name]
                end
              end
              if association_reflection[:type] == :belongs_to
                # Append associations foreign_key to data
                data[association_reflection[:foreign_key]] = self.send(association_reflection[:foreign_key])
                if association_reflection[:is_polymorphic]
                  foreign_type = self.class.extjs_polymorphic_type(association_reflection[:foreign_key])
                  data[foreign_type] = self.send(foreign_type)
                end
              end
            when :many
              value = association.collect { |r| r.to_record }  # use carefully, can get HUGE
            end
          else # not an association -> get the method's value
            value = self.send(field[:name])
            value = value.to_record if value.respond_to? :to_record
          end
          data[field[:name]] = value
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
      # The first parameter should be the fieldset for which the record definition will be returned.
      # If no parameter is provided, then the default fieldset will be choosen
      # Alternativly the first parameter can be a Hash with a :fields member to directly specify
      # the fields to use for the record config.
      #
      # All these are valid calls:
      #
      #  User.extjs_record             # returns record config for :default fieldset
      #                                # (fieldset is autmatically defined, if not set)
      #
      #  User.extjs_record :fieldset   # returns record config for :fieldset fieldset
      #                                # (fieldset is autmatically defined, if not set)
      #
      #  User.extjs_record :fields => [:id, :password]
      #                                # returns record config for the fields 'id' and 'password'
      #
      # For even more valid options for this method (which all should not be neccessary to use)
      # have a look at ExtJS::Model::Util.extract_fieldset_and_options
      def extjs_record(*params)
        fieldset, options = Util.extract_fieldset_and_options params

        if options[:fields].empty?
          fields = self.extjs_get_fields_for_fieldset(fieldset)
        else
          fields = self.process_fields(*options[:fields])
        end

        associations  = self.extjs_associations
        columns       = self.extjs_columns_hash
        pk            = self.extjs_primary_key
        rs            = []

        fields.each do |field|

          field = Marshal.load(Marshal.dump(field)) # making a deep copy

          if col = columns[field[:name]] # <-- column on this model
            rs << self.extjs_field(field, col)
          elsif assn = associations[field[:name]]
            # skip this association if we already visited it
            # otherwise we could end up in a cyclic reference
            next if options[:visited_classes].include? assn[:class]

            assn_fields = field[:fields]
            if assn[:class].respond_to?(:extjs_record)  # <-- exec extjs_record on assn Model.
              if assn_fields.nil?
                assn_fields = assn[:class].extjs_get_fields_for_fieldset(field.fetch(:fieldset, fieldset))
              end

              record = assn[:class].extjs_record(field.fetch(:fieldset, fieldset), { :visited_classes => options[:visited_classes] + [self], :fields => assn_fields})
              rs.concat(record[:fields].collect { |assn_field|
                self.extjs_field(assn_field, :parent_trail => field[:name], :mapping => field[:name], :allowBlank => true) # <-- allowBlank on associated data?
              })
            elsif assn_fields  # <-- :parent => [:id, :name, :sub => [:id, :name]]
              field_collector = Proc.new do |parent_trail, mapping, assn_field|
                if assn_field.is_a?(Hash) && assn_field.keys.size == 1 && assn_field.keys[0].is_a?(Symbol) && assn_field.values[0].is_a?(Array)
                  field_collector.call(parent_trail.to_s + self.extjs_parent_trail_template.call(assn_field.keys.first), "#{mapping}.#{assn_field.keys.first}", assn_field.values.first)
                else
                  self.extjs_field(assn_field, :parent_trail => parent_trail, :mapping => mapping, :allowBlank => true)
                end
              end
              rs.concat(assn_fields.collect { |assn_field| field_collector.call(field[:name], field[:name], assn_field) })
            else
              rs << extjs_field(field)
            end

            # attach association's foreign_key if not already included.
            if columns.has_key?(assn[:foreign_key]) && !rs.any? { |r| r[:name] == assn[:foreign_key] }
              rs << extjs_field({:name => assn[:foreign_key]}, columns[assn[:foreign_key]])
            end
            # attach association's type if polymorphic association and not alredy included
            if assn[:is_polymorphic]
              foreign_type = self.extjs_polymorphic_type(assn[:foreign_key])
              if columns.has_key?(foreign_type) && !rs.any? { |r| r[:name] == foreign_type }
                rs << extjs_field({:name => foreign_type}, columns[foreign_type])
              end
            end
          else # property is a method?
            rs << extjs_field(field)
          end
        end

        return {
          :fields => rs,
          :idProperty => pk
        }
      end

      ##
      # meant to be used within a Model to define the extjs record fields.
      # eg:
      # class User
      #   extjs_fieldset :grid, [:first, :last, :email => {"sortDir" => "ASC"}, :company => [:id, :name]]
      # end
      # or
      # class User
      #   extjs_fieldset :last, :email => {"sortDir" => "ASC"}, :company => [:id, :name] # => implies fieldset name :default
      # end
      #
      def extjs_fieldset(*params)
        fieldset, options = Util.extract_fieldset_and_options params
        var_name = :"@extjs_fieldsets__#{fieldset}"
        self.instance_variable_set( var_name, self.process_fields(*options[:fields]) )
      end

      def extjs_get_fields_for_fieldset(fieldset)
        var_name = :"@extjs_fieldsets__#{fieldset}"
        super_value = nil
        unless self.instance_variable_get( var_name )
          if self.superclass.respond_to? :extjs_get_fields_for_fieldset
            super_value = self.superclass.extjs_get_fields_for_fieldset(fieldset)
          end
          self.extjs_fieldset(fieldset, self.extjs_column_names) unless super_value
        end
        super_value || self.instance_variable_get( var_name )
      end

      ##
      # shortcut to define the default fieldset. For backwards-compatibility.
      #
      def extjs_fields(*params)
        self.extjs_fieldset(:default, {
          :fields => params
        })
      end

      ##
      # Prepare a field configuration list into a normalized array of Hashes, {:name => "field_name"}
      # @param {Mixed} params
      # @return {Array} of Hashes
      #
      def process_fields(*params)
        fields = []
        if params.size == 1 && params.last.is_a?(Hash) # peek into argument to see if its an option hash
          options = params.last
          if options.has_key?(:additional) && options[:additional].is_a?(Array)
            return self.process_fields(*(self.extjs_column_names + options[:additional].map(&:to_sym)))
          elsif options.has_key?(:exclude) && options[:exclude].is_a?(Array)
            return self.process_fields(*(self.extjs_column_names - options[:exclude].map(&:to_sym)))
          elsif options.has_key?(:only) && options[:only].is_a?(Array)
            return self.process_fields(*options[:only])
          end
        end

        params = self.extjs_column_names if params.empty?

        associations = extjs_associations

        params.each do |f|
          if f.kind_of?(Hash)
            if f.keys.size == 1 && f.keys[0].is_a?(Symbol) && f.values[0].is_a?(Array) # {:association => [:field1, :field2]}
              fields << {
                :name => f.keys[0],
                :fields => process_fields(*f.values[0])
              }
            elsif f.keys.size == 1 && f.keys[0].is_a?(Symbol) && f.values[0].is_a?(Hash) # {:field => {:sortDir => 'ASC'}}
              fields << f.values[0].update(:name => f.keys[0])
            elsif f.has_key?(:name) # already a valid Hash, just copy it over
              fields << f
            else
              raise ArgumentError, "encountered a Hash that I don't know anything to do with `#{f.inspect}:#{f.class}`"
            end
          else # should be a String or Symbol
            raise ArgumentError, "encountered a fields Array that I don't understand: #{params.inspect} -- `#{f.inspect}:#{f.class}` is not a Symbol or String" unless f.is_a?(Symbol) || f.is_a?(String)
            fields << {:name => f.to_sym}
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
          if config.has_key?(:mapping) && config.has_key?(:parent_trail)
            field.update( # <-- We use a template for rendering mapped field-names.
              :name => config[:parent_trail].to_s + self.extjs_parent_trail_template.call(field[:name]),
              :mapping => "#{config[:mapping]}.#{field[:name]}"
            )
          end
          field.update(config.except(:mapping, :parent_trail))
        elsif !config.nil?  # <-- Hopfully an ORM Column object.
          field.update(
            :allowBlank => self.extjs_allow_blank(config),
            :type => self.extjs_type(config),
            :defaultValue => self.extjs_default(config)
          )
          field[:dateFormat] = "c" if field[:type] === "date" && field[:dateFormat].nil? # <-- ugly hack for date
        end
        field.update(:type => "auto") if field[:type].nil?
        # convert Symbol values to String values
        field.keys.each do |k|
          raise ArgumentError, "extjs_field expects a Hash as first parameter with all it's keys Symbols. Found key #{k.inspect}:#{k.class.to_s}" unless k.is_a?(Symbol)
          field[k] = field[k].to_s if field[k].is_a?(Symbol)
        end
        field
      end

      # ##
      # # Returns an array of symbolized association names that will be referenced by a call to to_record
      # # i.e. [:parent1, :parent2]
      # #
      # def extjs_used_associations
      #   if @extjs_used_associations.nil?
      #     assoc = []
      #     self.extjs_record_fields.each do |f|
      #       #This needs to be the first condition because the others will break if f is an Array
      #       if extjs_associations[f[:name]]
      #         assoc << f[:name]
      #       end
      #     end
      #     @extjs_used_associations = assoc.uniq
      #   end
      #   @extjs_used_associations
      # end
    end

    module Util

      ##
      # returns the fieldset from the arguments and normalizes the options.
      # @return [{Symbol}, {Hash}]
      def self.extract_fieldset_and_options arguments
        orig_args = arguments
        fieldset = :default
        options = { # default options
          :visited_classes => [],
          :fields => []
        }
        if arguments.size > 2 || (arguments.size == 2 && !arguments[0].is_a?(Symbol))
          raise ArgumentError, "Don't know how to handle #{arguments.inspect}"
        elsif arguments.size == 2 && arguments[0].is_a?(Symbol)
          fieldset = arguments.shift
          if arguments[0].is_a?(Array)
            options.update({
              :fields => arguments[0]
            })
          elsif arguments[0].is_a?(Hash)
            options.update(arguments[0])
          end
        elsif arguments.size == 1 && (arguments[0].is_a?(Symbol) || arguments[0].is_a?(String))
          fieldset = arguments.shift.to_sym
        elsif arguments.size == 1 && arguments[0].is_a?(Hash)
          fieldset = arguments[0].delete(:fieldset) || :default
          options.update(arguments[0])
        end
        [fieldset, options]
      end
    end
  end
end

