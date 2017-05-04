#!/usr/bin/ruby
# Translate the Json to (crude) Ruby
$: << "lib"
require "robot"

ARGV.each do |base|
  base = base.sub(/\.ev3j$/, "")
  r = Ev3j::RobotProgram.from_json_file(base + ".ev3j")
  r.save_rb(base + ".out.rb")
  system "diff -u '#{base}.rb' '#{base}.out.rb'"
end
