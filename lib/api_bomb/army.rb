class ApiBomb::Army
  attr_reader :fighters

  def initialize(fighters:)
    @fighters = fighters
  end

  def send_fighter
    @fighters.future.fire
  end
  alias_method :send_new_fighter, :send_fighter
end
