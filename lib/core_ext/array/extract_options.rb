##
# add Rails-style Array#extract_options! method
#
module ExtJS
  module CoreExtensions
    module Array
      module ExtractOptions
        def extract_options!
          last.is_a?(::Hash) ? pop : {}
        end
      end
    end
  end
end
Array.send(:include, ExtJS::CoreExtensions::Array::ExtractOptions)