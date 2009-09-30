module ExtJS
    class MVC
      cattr_accessor :success_property
      cattr_accessor :message_property
      cattr_accessor :root

      if defined?(ActiveRecord)
        require 'active_record/model'
      end
      require 'extjs/component'
      require 'extjs/data/store'

      require 'helpers/component'
      require 'helpers/store'

      require 'action_controller/controller'

   end
end