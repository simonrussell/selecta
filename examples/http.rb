#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '../lib')
require 'selecta'

require 'socket'
gem 'http_parser.rb'
require 'http/parser'

class HttpWatcher
  def initialize(stream)
    @stream = stream
    @parser = Http::Parser.new(self)
  end

  def readable!
    text = @stream.read_nonblock(1000)
    @parser << text
  end

  def on_headers_complete(headers)
    @headers = headers
  end

  def on_message_complete
    @stream.write("HTTP/1.0 200 OK\r\n\r\nDust me selecta...")
    @stream.close
  end

end

loop = Selecta::EventLoop.new

listeners = Socket.tcp_server_sockets(3000)
listeners.each { |listener| listener.listen(20) }

#puts Process.fork.inspect

loop.watch(listeners, Selecta::Basic::Acceptor.new(HttpWatcher))

puts "listening..."
loop.run
