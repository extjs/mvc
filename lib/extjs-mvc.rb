module ExtJS
    class MVC
      @@success_property = :success
      @@message_property = :message
      @@root = :data
      cattr_accessor :success_property
      cattr_accessor :message_property
      cattr_accessor :root
      
      require 'model/base'
      
      # Detect orm, include appropriate mixin.
      if defined?(ActiveRecord)
        require 'model/active_record'
      elsif defined?(DataMapper)
        require 'model/data_mapper'
      elsif defined?(MongoMapper)
        require 'model/mongo_mapper'
      end

      # Rails-style Array#extract_options! used heavily
      if defined?(Merb)
        require 'core_ext/array/extract_options'
      end

      # ExtJS Component and Store wrappers
      require 'extjs/component'
      require 'extjs/data/store'

      # Component/Store view-helpers
      require 'helpers/component'
      require 'helpers/store'

      # Controller mixin.  Works for both Rails and Merb.
      require 'controller/controller'
   end
end

