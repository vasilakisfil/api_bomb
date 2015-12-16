require_relative "api_bomb/version"
require "benchmark"
require 'celluloid/current'
require 'http'
require 'pickup'
require 'pry'
require 'descriptive_statistics'
require 'descriptive_statistics/safe'

module ApiBomb
  class War
    attr_reader :fronts, :duration, :paths, :headers, :base_url, :logger
    def initialize(opts = {})
      @fronts = opts[:fronts] || 2
      @duration = opts[:duration] || 10
      @paths = opts[:paths] || ''
      @headers = opts[:headers] || {}
      @base_url = opts[:base_url] || ''
      @logger = opts[:logger] || Logger.new(STDOUT)
    end

    def start!
      if paths.is_a? String
        @logger.info("#{path_report(paths)}, duration: #{duration} sec")
        start_attack!(paths)
      elsif paths.is_a? Array
        paths.each do |path|
          @logger.info("#{path_report(path)}, duration: #{duration} sec")
          start_attack!(path)
          @logger.info("")
        end
      else
        @logger.info(probabilistic_paths_report)
        start_attack!(paths)
      end
    end

    def dereference_path(path)
      return path.call if path.respond_to? :call
      path
    end

    def start_attack!(testing_paths)
      Commander.new(
        fronts: fronts,
        duration: DURATION,
        army: Army.new(
          fighters: Fighter.pool(
            size: 2*fronts, args: [
              paths: testing_paths, headers: headers, base_url: base_url
            ]
          )
        ),
        logger: logger
      ).start_attack!
    end

    def path_report(path)
      if path.respond_to? :call
        return "Testing random paths like: #{path.call}"
      else
        return "Testing fixed path: #{path}"
      end
    end

    def probabilistic_paths_report
      return unless paths.is_a? Hash

      sum = paths.values.sum

      str =  "Load generation over random (weighted) urls \n"
      paths.sort_by {|_key, value| value}.to_h.each do |path, weight|
        str += "#{path_report(path)} with probability #{weight/sum} \n"
      end

      return str
    end
  end
end

require_relative 'api_bomb/strategies'
require_relative 'api_bomb/army'
require_relative 'api_bomb/fighter'
require_relative 'api_bomb/commander'
require_relative 'api_bomb/signaler'
