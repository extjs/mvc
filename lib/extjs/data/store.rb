##
# ExtJS::Data::Store
#
module ExtJS::Data
  class Store
    attr_accessor :id, :format, :type, :controller, :model

    def initialize(*params)
      options = params.extract_options!
      options[:format] = 'json' if options[:format].nil?
      
      @config     = options[:config]
      @format     = options[:format]
      @proxy      = options[:proxy] || 'http'
      @writer     = options[:writer]
      @type       = (options[:type].nil?) ? @proxy === 'direct' ? 'Ext.data.DirectStore' : "Ext.data.#{@format.capitalize}Store" : options[:type] 
      @controller = self.get_controller(options[:controller])
      @model      = self.get_model(options[:controller], options[:model])

      # Merge Reader/Proxy config
      @config.merge!(@controller.extjs_reader(@model, options[:fieldset] || :default))
      @config.merge!(@controller.extjs_proxy(options))
      @config["format"] = @format

      # Set storeId implicitly based upon Model name if not set explicitly
      @id = @config["storeId"] = @model.to_s.downcase unless @config["storeId"]
    end

    ##
    # pre-load a store with data.  Not yet tested.  In theory, this *should* work.
    #
    def load(*params)
      #@config["loadData"] = @model.all(params).collect {|rec| rec.to_record }
    end

    ##
    # renders the configured store
    # @param {Boolean} script_tag [true] Not yet implemented.  Always renders <script></script> tags.
    def render(script_tag = true)
      script = ''
      # ugly hack for DirectProxy API.  Have to add an Ext.onReady() after the Store constructor to set API
      if @proxy === 'direct'
        auto_load = @config.delete("autoLoad")
        cname = @controller.controller_name.capitalize
        script = "Ext.onReady(function() { var s = Ext.StoreMgr.get('#{@config["storeId"]}');"
        if (@config["directFn"])
          script += "s.proxy.directFn = #{cname}.#{@config["directFn"]};"
        else
          script += "s.proxy.setApi({create:#{cname}.#{@config["api"]["create"]},read:#{cname}.#{@config["api"]["read"]},update:#{cname}.#{@config["api"]["update"]},destroy:#{cname}.#{@config["api"]["destroy"]}});"
        end
        if auto_load
          script += "s.load();"
        end
        script += "});"
      end

      if @writer  # <-- ugly hack because 3.0.1 can't deal with Writer as config-param
        json = @config.to_json
        json[json.length-1] = ','
        json += "\"writer\":new Ext.data.#{@format.capitalize}Writer(#{@writer.to_json})}"
        "<script>new #{@type}(#{json});#{script}</script>"
      else
        "<script>new #{@type}(#{@config.to_json});#{script}</script>"
      end
    end

    def get_controller(name)
      if (defined?(Rails))
        "#{name.to_s.camelize}Controller".constantize
      else
        Extlib::Inflection.constantize("#{Extlib::Inflection.camelize(name)}")
      end
    end

    def get_model(controller, model)
      if (defined?(Rails))
        ((model) ? model : controller.singularize).camelize.constantize
      else
        Extlib::Inflection.constantize(Extlib::Inflection.camelize(((model) ? model : Extlib::Inflection.singularize(controller))))
      end
    end
  end
end
