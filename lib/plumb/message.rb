module Plumb
  class Message < String
    def to_json(*)
      self
    end

    def [](key)
      attributes[key]
    end

    def attributes
      JSON.parse(self)
    end
  end
end
