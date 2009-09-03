module ExtJS::Helpers
  module Component
    def extjs_create_component(params)
      ExtJS::Component.new(params)
    end
  end
end

class ExtJS::Component

  def initialize(params)
    @params = params
    @params[:items] = [] if @params[:items].nil?
  end

  def add(p)
    @params[:items] << p
  end

  def render
    cmp = "Ext.ComponentMgr.create(#{@params.to_json});"
    "<script>Ext.onReady(function() {#{cmp}});</script>"
  end
end
