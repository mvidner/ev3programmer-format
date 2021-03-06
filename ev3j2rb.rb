#!/usr/bin/ruby
# Translate the Json to (crude) Ruby
$: << "lib"
require "ev3j"

ARGV.each do |base|
  base = base.sub(/\.ev3j$/, "")
  r = Ev3j::Robot.new
  r.json_file(base + ".ev3j")
  r.save_rb(base + ".out.rb")
  `rubocop -a '#{base + ".out.rb"}'`
  system "diff -u '#{base}.rb' '#{base}.out.rb'"
end
