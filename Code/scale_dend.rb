#!/usr/bin/env ruby
## scale dendrites and axons
## author: stephanmg
require 'csv'

if ARGV.length != 2 
  puts "Usage: #{$0} FILENAME SCALE_FACTOR"
  exit
end

fname = ARGV[0]
scale = ARGV[1].to_f

CSV.foreach(fname, headers:false, col_sep:' ') do |row| 
  id, type, x, y, z, diam, pid = row
  # scale all except somata
  if (type != "1") then diam = diam.to_f * scale end
  puts "#{id}\t#{type}\t#{x}\t#{y}\t#{z}\t#{diam}\t#{pid}"
end
