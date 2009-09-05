module ExtJS::Helpers
  module Store
    def extjs_store(*params)
      ExtJS::Data::Store.new(params)
    end
  end
end
