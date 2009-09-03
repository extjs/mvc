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
      require 'action_view/helpers/component'
      require 'action_controller/controller'
      require 'action_view/helpers/store'
   end
end


