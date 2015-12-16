class ApiBomb::Fighter
  include Celluloid

  attr_reader :paths

  def initialize(paths: nil)
    @paths = PathPicker.new(paths)
  end

  def fire
    url = API_URL + @paths.pick
    response = nil
    hold_time = Benchmark.measure do
      response = HTTP.get(url, headers: {
        'Session-Token' => SESSION_TOKEN,
        'Connection' => 'close'
      })
    end

    return OpenStruct.new(response: response, hold_time: hold_time.real)
  end

  class PathPicker
    attr_reader :paths
    def initialize(paths)
      return @paths = Pickup.new(paths) if paths.is_a? Hash
      @paths = [paths].flatten
    end

    def pick
      path = paths.pick if paths.is_a? Pickup
      path = paths.sample if paths.is_a? Array

      return path.call if path.respond_to? :call

      return path
    end
  end
end
