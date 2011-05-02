class Selecta::EventLoop

  def initialize
    @map = {}
    @read_list = []
  end

  def watch(io, watcher = nil, &block)
    if watcher.nil? && block
      watcher = Object.new
      watcher.instance_eval(&block)
    end

    if io.is_a?(Array)
      io.each { |inner_io| watch(inner_io, watcher) }
    else
      @map[io] = watcher
      @read_list << io if watcher.respond_to?(:readable!) || watcher.respond_to?(:acceptable!)
    end
  end

  def run
    while true
      result = IO.select(@read_list, nil, nil, nil)

      result[0].each do |io|
        watcher = @map[io]

        if watcher.respond_to?(:readable!)
          if io.eof?
            remove_io(watcher, io)
          else
            call_watcher(watcher, io, :readable!)
          end
        elsif watcher.respond_to?(:acceptable!)
          call_watcher(watcher, io, :acceptable!)
        end
      end
    end
  end

  private

  def remove_io(watcher, io)
    @map.delete(io)
    @read_list.delete(io)
    call_watcher(watcher, io, :closed!) if watcher.respond_to?(:closed!)
  end

  def call_watcher(watcher, io, method_name)
    case watcher.method(method_name).arity
    when 2
      watcher.send(method_name, io, self)
    when 1
      watcher.send(method_name, io)
    when 0
      watcher.send(method_name)
    else
      raise "weird arity!"
    end

    remove_io(watcher, io) if io.closed? 
  end

end
