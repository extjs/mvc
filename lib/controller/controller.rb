module ExtJS::Controller

  def self.included(controller)
    controller.send(:extend, ClassMethods)
  end

  ##
  # Controller class methods
  #
  module ClassMethods

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
