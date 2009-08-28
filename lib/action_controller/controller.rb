module ExtJS::Controller

  def self.included(controller)
    controller.send(:extend, ClassMethods)
  end

  ##
  # Controller class methods
  #
  module ClassMethods

    def extjs_reader(model)
      {
        "successProperty" => extjs_success_property,
        "root" => extjs_root,
        "messageProperty" => extjs_message_property
      }.merge(model.extjs_record)
    end

    def extjs_proxy(params)
      proxy = {}
      if params[:proxy] === 'direct'
        actions = ['create', 'read', 'update', 'destroy']
        proxy["api"] = {}
        direct_actions.each_index do |n|
          proxy["api"][actions[n]] = direct_actions[n][:name]
        end
      else
        if params[:config]["api"]
          proxy["api"] = {}
          params[:config]["api"].each {|k,v| proxy["api"][k] = "/#{params[:controller]}/#{v}" }
        else
          proxy["url"] = "/#{params[:controller]}.#{params[:format].to_s}"
        end
      end
      proxy
    end

    def extjs_root(value=nil)
      ExtJS::MVC.root = value unless value.nil?
      ExtJS::MVC.root
    end

    def extjs_success_property(value=nil)
      ExtJS::MVC.success_property = value unless value.nil?
      ExtJS::MVC.success_property
    end

    def extjs_message_property(value=nil)
      ExtJS::MVC.message_property = value unless value.nil?
      ExtJS::MVC.message_property
    end

  end
end
