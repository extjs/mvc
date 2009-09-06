##
# @class ExtJS::Component
#
class ExtJS::Component
  attr_accessor :config
  def initialize(params)
    @config = params#params.extract_options!
    @controller = @config.delete(:controller) unless @config[:controller].nil?

    @config[:items] = [] if config[:items].nil?

    if container = @config.delete(:container)
      container.add(self)
    end
    @partial_config = nil
  end

  def apply(params)
    @config.merge!(params)
  end

  ##
  # Adds a config {} or ExtJS::Component instance to this component's items collection.
  # NOTE:  When :partial option is used a String will of course be returned.  Otherwise an ExtJS::Component
  # instance will be returned.
  # @return {String/ExtJS::Component}
  def add(*config)
    options = config.extract_options!
    if !options.keys.empty?
      if url = options.delete(:partial)
        # rendering a partial, cache the config until partial calls #add method.  @see else.
        @partial_config = options
        return @controller.render(:partial => url, :locals => {:container => self})
      else
        options.merge!(@partial_config) unless @partial_config.nil?
        options[:controller] = @controller unless @controller.nil?
        cmp = ExtJS::Component.new(options)
        @partial_config = nil
        @config[:items] << cmp
        return cmp
      end
    elsif !config.empty? && config.first.kind_of?(ExtJS::Component)
      cmp = config.first
      cmp.apply(@partial_config) unless @partial_config.nil?
      @partial_config = nil
      @config[:items] << cmp.config
      return cmp
    end
  end

  def to_json
    config.to_json
  end

  def render
    # If there are any listeners attached in json, we have to get rid of double-quotes in order to expose
    # the javascript object.
    # eg:  "listeners":"SomeController.listeners.grid" -> {"listeners":SomeController.listeners.grid, ...}
    json = @config.to_json.gsub(/\"(listeners|handler|scope)\":\s?\"([a-zA-Z\.\[\]\(\)]+)\"/, '"\1":\2')
    "Ext.ComponentMgr.create(#{json});"
  end
end
