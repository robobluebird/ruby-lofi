class Writer
  def initialize buffer, name, channels, samplerate, format
    @buffer = buffer
    @name = name
    @channels = channels
    @samplerate = samplerate
    @format = format
  end

  def on_write &block
    @callback = block
    self
  end

  def write
    path = File.join Dir.pwd, "lofi", @name

    # FileUtils.rm_rf path
    
    info = RubyAudio::SoundInfo.new(
      channels: @channels,
      samplerate: @samplerate,
      format: @format
    )

    out = RubyAudio::Sound.open path, "w", info
    out.write @buffer
    out.close
    @callback.call path if @callback
  end
end
