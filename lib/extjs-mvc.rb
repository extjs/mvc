module ExtJS
    class MVC
      @@success_property = :success
      @@message_property = :message
      @@root = :data
      cattr_accessor :success_property
      cattr_accessor :message_property
      cattr_accessor :root

      if defined?(ActiveRecord)
        require 'active_record/model'
      end
      require 'extjs/component'
      require 'extjs/data/store'

      require 'action_view/helpers/component'
      require 'action_view/helpers/store'

      require 'action_controller/controller'

   end
end


