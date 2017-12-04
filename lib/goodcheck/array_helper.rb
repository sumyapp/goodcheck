module Goodcheck
  module ArrayHelper
    def array(obj)
      case obj
      when Hash
        [obj]
      else
        Array(obj)
      end
    end
  end
end
