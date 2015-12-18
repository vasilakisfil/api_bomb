class ApiBomb::Fighter
  include Celluloid

  attr_reader :paths, :options, :base_url

  def initialize(paths: nil, base_url: nil, options: {})
    @base_url = base_url
    @options = options
    @paths = paths
  end

  def fire
    route = @paths.pick

    url = URI::join(base_url, route.path)
    response = nil
    hold_time = Benchmark.measure do
      response = HTTP.send(
        route.action,
        url,
        ApiBomb::LambdaHash.hasharize(options.merge(route.options))
      )
    end

    return OpenStruct.new(response: response, hold_time: hold_time.real)
  end
end
