##
# @class ExtJS::Component
#
class ExtJS::Component
  attr_accessor :config
  def initialize(controller, params)
    @config = params.extract_options!
    @controller = controller

    @config[:items] = [] if config[:items].nil?

    if container = @config.delete(:container)
      container.add(self)
    end
    @partial_config = nil
  end

  def apply(params)
    @config.merge!(params)
  end

  def add(*config)
    options = config.extract_options!
    if !options.keys.empty?
      if url = options.delete(:partial)
        # rendering a partial, cache the config until partial calls #add method.  @see else.
        @partial_config = options
        return @controller.render(:partial => url, :locals => {:container => self})
      else
        options.merge!(@partial_config) unless @partial_config.nil?
        @config[:items] << options
      end
    elsif !config.empty? && config.first.kind_of?(ExtJS::Component)
      cmp = config.first
      cmp.apply(@partial_config) unless @partial_config.nil?
      @config[:items] << cmp.config
    end
    @partial_config = nil
  end

  def render
    # If there are any listeners attached in json, we have to get rid of double-quotes in order to expose
    # the javascript object.
    # eg:  "listeners":"SomeController.listeners.grid" -> {"listeners":SomeController.listeners.grid, ...}
    json = @config.to_json.gsub(/\"listeners\":\s?\"([a-zA-Z\.\[\]\(\)]+)\"/, '"listeners":\1')
    "Ext.ComponentMgr.create(#{json});"
  end
end