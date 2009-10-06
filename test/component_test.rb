require 'test_helper'

class ComponentTest < Test::Unit::TestCase
    context "An ExtJS::Component Instance" do

	setup do
	    @cmp = ExtJS::Component.new("title" => "A Component", "xtype" => "panel")
	end

	should "Render" do
	    assert @cmp.render.match(/Ext.ComponentMgr.create/)
	end
    end
end

