module ApiBomb::Path
  class Sequence
    include Enumerable
    extend Forwardable
    def_delegators :@paths, :each, :<<

    attr_reader :paths
    def initialize(paths)
      @paths = paths
    end

    def pick
      return paths.sample
    end
  end

  class Single
    HTTP_METHODS = [:get, :post, :put, :patch, :delete, :head].freeze

    def initialize(path:, action: :get, options: {})
      @path = path
      @action = action
      @action = :get if not HTTP_METHODS.include?(action.downcase.to_sym)
      @options = ApiBomb::LambdaHash.new(options)
    end

    def pick
      return self
    end

    def report(base_url)
      path_report(base_url) + params_report
    end

    def path_report(base_url = '')
      base_url = options[:base_url] if options[:base_url]

      if @path.respond_to? :call
        "testing random paths like #{action.to_s.upcase} #{URI::join(base_url, path)}"
      else
        "testing path #{action.to_s.upcase} #{URI::join(base_url, path)}"
      end
    end

    def params_report
      return '' unless options[:params]

      if options.is_lambda?
        " with random params like: #{ApiBomb::LambdaHash.hasharize(options)[:params]}"
      else
        " with params: #{options[:params]}"
      end
    end

    def path
      return @path.call if @path.respond_to? :call
      return @path
    end

    def action
      return @action.call if @action.respond_to? :call
      return @action
    end

    def options
      @options
    end
  end

  class Weighted
    attr_reader :weighted_paths, :paths
    def initialize(paths)
      @weighted_paths = Pickup.new(paths)
      @paths = paths
    end

    def pick
      Single.new(@weighted_paths.pick)
    end

    def report(base_url)
      sum = paths.values.sum

      str_array = []
      str_array << "Load generation over random (weighted) urls \n"
      paths.sort_by {|_key, value| value}.to_h.each do |path, weight|
        str_array << "#{Single.new(path).report(base_url)} with probability #{weight/sum} \n"
      end

      return str_array.join(' ')
    end
  end
end
