module ExtJS::Helpers
  module Store
    def extjs_store(params)
      params[:format] = 'json' if params[:format].nil?
      params[:proxy] = 'http' if params[:proxy].nil?

      controller = "#{params[:controller].to_s.capitalize}Controller".constantize
      model = ((params[:model]) ? params[:model] : params[:controller].singularize).capitalize.constantize

      reader = controller.extjs_reader(model)
      proxy = controller.extjs_proxy(params)

      params[:config]["storeId"] = model.to_s.downcase
      params[:config].merge!(reader)
      params[:config].merge!(proxy)

      type = (params[:proxy] === 'direct' ? params[:proxy] : params[:format]).capitalize

      script = ''
      # ugly hack for DirectProxy API.  Have to add an Ext.onReady() after the Store constructor to set API
      if params[:proxy] === 'direct'
        auto_load = params[:config].delete("autoLoad")
        cname = params[:controller].capitalize
        script = "Ext.onReady(function() { var s = Ext.StoreMgr.get('#{model.to_s.downcase}');"
        if (params[:config]["directFn"])
          script += "s.proxy.directFn = #{cname}.#{params[:config]["directFn"]};"
        else
          script += "s.proxy.setApi({create:#{cname}.#{params[:config]["api"]["create"]},read:#{cname}.#{params[:config]["api"]["read"]},update:#{cname}.#{params[:config]["api"]["update"]},destroy:#{cname}.#{params[:config]["api"]["destroy"]}});"
        end
        if auto_load
          script += "s.load();"
        end
        script += "});"
      end

      if params[:config]["writer"]  # <-- ugly hack because 3.0.1 can't deal with Writer as config-param
        writer = params[:config].delete("writer")
        json = params[:config].to_json
        json[json.length-1] = ','
        json += "writer:new Ext.data.#{params[:format].capitalize}Writer(#{writer.to_json})}"
        "new Ext.data.#{type}Store(#{json});#{script}"
      else
        "new Ext.data.#{type}Store(#{params[:config].to_json});#{script}"
      end

    end
  end
end
