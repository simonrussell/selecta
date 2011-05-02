class Selecta::Basic::Acceptor

  def initialize(klass)
    @klass = klass
  end 

  def acceptable!(socket, event_loop)
    stream = socket.accept_nonblock.first
    event_loop.watch(stream, @klass.new(stream))
  rescue IO::WaitReadable
    # nothing, can happen if two selects on the same socket (e.g. forked process)
  end

end
