require_relative "api_bomb/version"
require "benchmark"
require 'celluloid/current'
require 'http'
require 'pickup'
require 'pry'
require 'descriptive_statistics'
require 'descriptive_statistics/safe'
require 'forwardable'

module ApiBomb
  class War
    attr_reader :fronts, :duration, :paths, :options, :base_url, :logger,
      :requests
    #alias_method :path, :paths

    def initialize(opts = {})
      @fronts = opts[:fronts] || 2
      @duration = opts[:duration] || 10
      @paths = opts[:paths]
      @paths = (opts[:path] || '') if @paths.blank?
      @options = HashCall.new(opts[:options] || {})
      @base_url = opts[:base_url] || ''
      @logger = opts[:logger] || Logger.new(STDOUT)
      @requests = opts[:requests]
      build_paths
    end

    def build_paths
      case @paths
      when String
        @paths = SinglePath.new(path: @paths)
      when Array
        tmp_paths = []
        @paths.each do |path|
          if path.is_a? Hash
            tmp_paths << SinglePath.new(path)
          elsif path.is_a? String
            tmp_paths << SinglePath.new(path: path)
          else
            raise 'Unknown path structure'
          end
        end
        @paths = ArrayPaths.new(tmp_paths)
      when Hash
        @paths = SinglePath.new(@paths)
      else
        raise 'Unknown path structure'
      end
    end

    def start!
      case paths
      when SinglePath
        @logger.info("#{paths.report(base_url)}, duration: #{duration} sec")
        start_attack!(paths)
      when ArrayPaths
        paths.each do |path|
          @logger.info("#{path.report(base_url)}, duration: #{duration} sec")
          start_attack!(path)
        end
      when RandomPaths
        @logger.info(probabilistic_paths_report)
        start_attack!(paths)
      end
    end

    def dereference_path(path)
      return path.call if path.respond_to? :call
      return path[:path] if path.respond_to? :[] && path[:path] != nil
      path
    end

    def start_attack!(testing_paths)
      Commander.new(
        fronts: fronts,
        duration: duration,
        army: Army.new(
          fighters: Fighter.pool(
            size: 2*fronts, args: [
              paths: testing_paths, base_url: base_url, options: options
            ]
          )
        ),
        logger: logger,
        requests: requests
      ).start_attack!
    end

    def probabilistic_paths_report
      sum = paths.values.sum

      str =  "Load generation over random (weighted) urls \n"
      paths.sort_by {|_key, value| value}.to_h.each do |path, weight|
        str += "#{path} with probability #{weight/sum} \n"
      end

      return str
    end
  end

  class ArrayPaths
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

  class SinglePath
    HTTP_METHODS = [:get, :post, :put, :patch, :delete, :head].freeze

    def initialize(path:, action: :get, options: {})
      @path = path
      @action = action
      @action = :get if not HTTP_METHODS.include?(action.downcase.to_sym)
      @options = HashCall.new(options)
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
      if options.real[:params].respond_to? :call
        " with random params like: #{options[:params]}"
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

  class RandomPaths < SimpleDelegator
    attr_reader :weighted_paths
    def initialize(paths)
      @weighted_paths = Pickup.new(paths)
      @paths = paths
      super(@paths)
    end

    def pick
      HashCall.new(@weighted_paths.pick)
    end
  end

  #values can respond to call making them dynamic
  class HashCall < SimpleDelegator
    def self.hasharize(hash)
      hash_call = self.new(hash)
      h = {}
      hash_call.each do |v, k|
        h[v] = hash_call[v]
        if h[v].is_a? HashCall
          h[v] = self.hasharize(h[v])
        end
      end

      return h
    end

    def [](key)
      value = self.__getobj__[key]
      value = value.call if value.respond_to? :call
      value =  self.class.new(value) if value.is_a? Hash

      return value
    end

    def real
      self.__getobj__
    end
  end
end

require_relative 'api_bomb/strategies'
require_relative 'api_bomb/army'
require_relative 'api_bomb/fighter'
require_relative 'api_bomb/commander'
require_relative 'api_bomb/signaler'
