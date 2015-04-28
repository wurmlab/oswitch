class OSwitch
  class ENOPKG < StandardError
    def initialize(name)
      @name = name
    end

    def to_s
      "Recipe to run #@name not available."
    end
  end

  class ENODKR < StandardError
    def to_s
      "***** Docker not installed / correctly setup / running.
      Are you able to run 'docker info'?"
    end
  end
end
