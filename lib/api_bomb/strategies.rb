module ApiBomb::Strategies
  module Naive
    def attack
      if requests
        attack_in_requests
      else
        attack_in_time
      end
    end

    def attack_in_time
      fronts.times do |i|
        @fighters << @army.send_fighter
      end

      while (@fighters.length > 0) do
        signaler.report(@fighters[0])
        @fighters.shift

        @fighters << @army.send_new_fighter
      end
    end

    def attack_in_requests
      requests.times do |i|
        @fighters << @army.send_fighter
      end

      while (@fighters.length > 0) do
        signaler.report(@fighters[0])
        @fighters.shift
      end
    end
  end
end
