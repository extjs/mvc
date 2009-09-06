##
# ExtJS::Helpers::Component
#
module ExtJS::Helpers
  module Component
    ##
    # add class-var @@extjs_on_ready
    def self.included(helper)
    
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
      @onready_queue = [] if @onready_queue.nil?

      params.each do |cmp|
	@onready_queue << cmp
      end
    end

    ##
    # Empties the on_ready queue.  Renders within <script></script> tags
    #
    def extjs_render
      @onready_queue = [] if @onready_queue.nil? # <--- ugly, ugh...having trouble with initializing my instance vars.
      "<script>\nExt.onReady(function() {\n\t#{@onready_queue.collect {|cmp| (cmp.kind_of?(ExtJS::Component)) ? cmp.render : cmp}.join("\n\t")}\n });\n</script>"
    end
  end
end
