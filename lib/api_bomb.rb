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
    attr_reader :fronts, :duration, :paths, :headers, :base_url
    def initialize(opts = {})
      @fronts = opts[:fronts] || 2
      @duration = opts[:duration] || 10
      @paths = opts[:paths] || ''
      @headers = opts[:headers] || {}
      @base_url = opts[:base_url] || ''
    end

    def start!
      if paths.is_a? String
        puts "#{path_report(paths)}, duration: #{duration} sec"
        start_attack!(paths)
      elsif paths.is_a? Array
        paths.each do |path|
          puts "#{path_report(path)}, duration: #{duration} sec"
          start_attack!(path)
          puts
        end
      else
        puts probabilistic_paths_report
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
        )
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

      multiplier = 100 / paths.max[1]

      puts "Load generation over random (weighted) urls"
      paths.each do |k, v|
        puts "#{array_path_path(path)} with probability #{multiplier * v }"
      end

    end
  end
end

require_relative 'api_bomb/strategies'
require_relative 'api_bomb/army'
require_relative 'api_bomb/fighter'
require_relative 'api_bomb/commander'
require_relative 'api_bomb/signaler'
