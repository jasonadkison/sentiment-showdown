require "rubygems"
require "bundler/setup"
Bundler.require

MASHAPE_KEY = "HbHGB1H3tOmshvjTKkHZoiGycNVDp1195AzjsngIlOOoqX5xNo"
MICROSOFT_KEY = "eb6ff9a46257409f950ede841eae0ce0"

require_relative "lib/showdown"

$VERBOSE = nil

class Sentiment
  POSITIVE = :positive
  NEGATIVE = :negative
  NEUTRAL  = :neutral
end

Showdown.new.run
