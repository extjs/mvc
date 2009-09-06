##
# ExtJS::Helpers::Component
#
module ExtJS::Helpers
  module Component
    ##
    # add class-var @@extjs_on_ready
    def self.included(controller)
      controller.class_eval do
        @@onready_queue = []
      end
    end

    def extjs_component(*params)
      options = params.extract_options!
      options[:controller] = self
      ExtJS::Component.new(options)
    end

    ##
    # Adds a script or ExtJS::Component instance to on_ready queue.  The queue is emptied and rendered to
    # <script></script> via #extjs_render
    #
    def extjs_onready(*params)
      params.each do |cmp|
        @@onready_queue << cmp
      end
    end

    ##
    # Empties the on_ready queue.  Renders within <script></script> tags
    #
    def extjs_render
      "<script>\nExt.onReady(function() {\n\t#{@@onready_queue.collect {|cmp| (cmp.kind_of?(ExtJS::Component)) ? cmp.render : cmp}.join("\n\t")}\n });\n</script>"
    end
  end
end
