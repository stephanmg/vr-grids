#!/usr/bin/env ruby -w
## author: stephanmg <stephan@syntaktischer-zucker.de>
## summary: curates a SWC, e.g. shifts multi branches, merges soma, fixes identifiers 

# libraries
require 'optparse'

# constants
Message = "Usage: tame_branching.rb -f FILENAME [options] [-hdims]"
Header = "# This file has been generated by TAME_BRANCHING"
NumSupportedBranches, SomaType = 1, 1
DendriteType, ShiftWidth = 4, 1

# options
options, usage = {}, lambda { puts Message; exit() }
OptionParser.new do |opts|
  opts.banner = Message
  opts.on('-f', '--filename FILENAME', 'File name') { |file| options[:file_name] = file }
  opts.on('-d', '--dryrun', 'Dry run - Just show multi branching') { |d| options[:dryrun] = d }
  opts.on('-h', '--help', 'Display a help message') { |h| options[:help] = h; puts opts }
  opts.on('-i', '--identifier', 'Correct identifiers') { |i| options[:identifier] = i }
  opts.on('-m', '--merge', "Merge soma") { |m| options[:merge] = m }
  opts.on('-s', '--shift', "Shift multi-branches") { |s| options[:shift] = s }
end.parse!
if options[:file_name].nil? then ! options[:help] ? usage.call() : exit() end

# read data and drop header comments starting with a hash 
$,, $; = " ", " "
lines = []
File.foreach(options[:file_name]).each do |line|
  lines << line.split.each_with_index.map { |elem, i| ([0,1,6].include?i) ? elem.to_i : elem.to_f } if not line =~ /^#/;
end

# correct identifiers 
if options[:identifier]
  lines.each do |line|
    case line[1]
    when 1 then line[1] = DendriteType
    when 2 then line[1] = SomaType
    end
  end
end

# find duplicated parent ids for detecting multi branches
duplicates = lines.group_by(&:last).select{|k, v| v.count > NumSupportedBranches}.keys
encountered = Hash[ *duplicates.collect { |v| [ v, 0 ] }.flatten ]

# just shows multi branches and exists
if options[:dryrun] 
  puts "Multi-branches (n > #{NumSupportedBranches}): #{duplicates}"; exit()
end

# merge soma into first point with soma identifier
lines_clean = []
if options[:merge]
  somaFound, somaIndex = false, -1
  somaRanges, first, last = [], 0, 0
  selector = lambda { |el, arr| (arr.first..arr.last) === el }
  lines.each_with_index do |line, index|
    if line[1] == SomaType 
       if not somaFound
         first = index # start index of current soma part
         somaFound = true # first point with type SomaType assigned as singleton soma
         if somaIndex == -1 then lines_clean << line; somaIndex = index; end 
       end
      last = index # end index of current soma part
    else
      somaFound = false # new soma part could start now
      somaRanges << [first, last] # store found the soma range found so far
      if not somaRanges.select(&selector.curry[line[-1]]).empty? # just for fun
        line[-1] = somaIndex + 1
      else
        line[-1] = line[-1] - (last - first)
      end
      line[0] = line[0] - (last - first)
      lines_clean << line
    end
  end
else
  lines_clean = lines
end

# shift branches
lines_shifted = []
if options[:shift]
  lines_clean.each do |line|
    id = line[-1]
    if duplicates.include?(id)
      if encountered[id] > NumSupportedBranches
        line[-1] = line[-1] + ShiftWidth
      end
    end
    lines_shifted << line
  end
else
  lines_shifted = lines_clean
end

# output a new SWC file
lines_shifted.each do |line| puts line.join end
