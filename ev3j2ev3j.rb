#!/usr/bin/ruby
# Check that we can do a round-trip of the ev3j format
# via the Ruby object representation
$: << "lib"
require "ev3j"

ARGV.each do |base|
  base = base.sub(/\.ev3j$/, "")
  r = Ev3j::Robot.new
  r.json_file(base + ".ev3j")
  r.save_json(base + ".out.ev3j")
  system "python -m json.tool '#{base}.out.ev3j' > '#{base}.out.pp.ev3j'"
  system "diff -u '#{base}.pp.ev3j' '#{base}.out.pp.ev3j'"
end
