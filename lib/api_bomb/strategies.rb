module ApiBomb::Strategies
  module Naive
    def attack
      fronts.times do |i|
        @fighters << @army.send_fighter
      end

      while (@fighters.length > 0) do
        signaler.report(@fighters[0])
        @fighters.shift

        @fighters << @army.send_new_fighter
      end
    end
  end
end
