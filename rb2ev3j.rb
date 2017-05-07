#!/usr/bin/ruby
$: << "lib"
require "ev3j"

ARGV.each do |base|
  base = base.sub(/\.rb$/, "")
  r = Ev3j::Robot.new
  r.script_file(base + ".rb")
  r.save_json(base + ".out.ev3j")
  system "python -m json.tool #{base}.out.ev3j > #{base}.out.pp.ev3j"
  system "diff -u #{base}.pp.ev3j #{base}.out.pp.ev3j"
end
