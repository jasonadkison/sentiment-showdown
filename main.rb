require "rubygems"
require "bundler/setup"
Bundler.require

require_relative "lib/showdown"

$VERBOSE = nil

class Sentiment
  POSITIVE = :positive
  NEGATIVE = :negative
  NEUTRAL  = :neutral
end

Showdown.new.run
