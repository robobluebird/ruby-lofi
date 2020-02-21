class Player
  attr_reader :path

  def initialize path
    @path = path
    @song = Gosu::Song.new @path if @path
  end

  def on_update &block
    @update_callback = block
  end

  def on_done &block
    @done_callback = block
  end

  def path= new_path
    @path = new_path
  end

  def playing?
    @song && @song.playing?
  end

  def toggle resume = false
    if @song.playing?
      resume ? @song.pause : @song.stop
      @thread.join if @thread
    else
      @song.play
      @thread = Thread.new do
        time = 0.0
        while @song.playing?
          @update_callback.call time if @update_callback
          sleep 0.25
          time += 0.25
        end
        @done_callback.call if @done_callback
      end
    end
  end
end
