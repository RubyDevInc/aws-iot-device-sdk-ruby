require 'pi_piper'
include PiPiper

puts "Press the swith to get started"

var = 0

after :pin => 17, :goes => :high do |pin|
  var = 1 - var
  puts "Button got pressed and variable changed to value #{var}"
end

PiPiper.wait
