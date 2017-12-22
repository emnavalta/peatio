#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "bunny"
require "benchmark"

conn = Bunny.new
conn.start
ch   = conn.create_channel

puts
puts "-" * 80
puts "Benchmarking on #{RUBY_DESCRIPTION}"

n  = 4000

# warm up the JIT, etc
puts "Doing a warmup run..."
n.times { ch.queue("", :exclusive => true).bind("amq.fanout") }

t  = Benchmark.realtime do
  n.times { ch.queue("", :exclusive => true).bind("amq.fanout") }
end
r  = (n.to_f/t.to_f)

puts "queue.declare + queue.bind rate: #{(r / 1000).round(2)} KGHz"
puts
puts "-" * 80
