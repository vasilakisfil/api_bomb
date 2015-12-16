require_relative "api_bomb/version"
require "benchmark"
require 'celluloid/current'
require 'http'
require 'pickup'
require 'pry'
require 'descriptive_statistics'
require 'descriptive_statistics/safe'

module ApiBomb
end

require_relative 'api_bomb/strategies'
require_relative 'api_bomb/army'
require_relative 'api_bomb/fighter'
require_relative 'api_bomb/commander'
require_relative 'api_bomb/signaler'
