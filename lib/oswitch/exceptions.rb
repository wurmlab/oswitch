class OSwitch
  class ENODKR < StandardError
    def to_s
      "***** Docker not installed / correctly setup / running.
      Are you able to run 'docker info'?"
    end
  end
end
