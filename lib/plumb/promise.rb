module Plumb
  class Promise
    def initialize(on_fulfil, on_break)
      @on_fulfil = on_fulfil
      @on_break = on_break
    end

    def fulfil
      @on_fulfil.call
    end

    def break
      @on_break.call
    end
  end
end
