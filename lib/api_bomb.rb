require_relative "api_bomb/version"
require "benchmark"
require 'celluloid/current'
require 'http'
require 'pickup'
require 'pry'
require 'descriptive_statistics'
require 'descriptive_statistics/safe'
require 'forwardable'

require_relative 'api_bomb/lambda_hash'
require_relative 'api_bomb/strategy'
require_relative 'api_bomb/path'

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
      @options = LambdaHash.new(opts[:options] || {})
      @base_url = opts[:base_url] || ''
      @logger = opts[:logger] || Logger.new(STDOUT)
      @requests = opts[:requests]
      build_paths
    end

    def build_paths
      case @paths
      when String
        @paths = Path::Single.new(path: @paths)
      when Array
        tmp_paths = []
        @paths.each do |path|
          if path.is_a? Hash
            tmp_paths << Path::Single.new(path)
          elsif path.is_a? String
            tmp_paths << Path::Single.new(path: path)
          else
            raise 'Unknown path structure'
          end
        end
        @paths = Path::Sequence.new(tmp_paths)
      when Hash
        @paths = Path::Single.new(@paths)
      when Path::Single, Path::Sequence, Path::Weighted
      else
        raise 'Unknown path structure'
      end
    end

    def start!
      case paths
      when Path::Single
        @logger.info("#{paths.report(base_url)}, duration: #{duration} sec")
        start_attack!(paths)
      when Path::Sequence
        paths.each do |path|
          @logger.info("#{path.report(base_url)}, duration: #{duration} sec")
          start_attack!(path)
        end
      when Path::Weighted
        @logger.info(paths.report)
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
  end

end

require_relative 'api_bomb/army'
require_relative 'api_bomb/fighter'
require_relative 'api_bomb/commander'
require_relative 'api_bomb/signaler'
