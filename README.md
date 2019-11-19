# ruby-lofi
ruby lofi

HELLO

To run this app:

You must have `sox` installed. Checkout out `http://sox.sourceforge.net/` to install it. This handles taking our audio data and turning it into sound! I apologize for the dependency, maybe in the future it can be removed...

1. `git clone https://github.com/robobluebird/ruby-lofi`
2. `cd ruby-lofi`
3. `unzip sounds.zip`
4. `cd ..`
5. `ruby ruby-lofi/app.rb`

To work on this app:

1. The entry point is `app.rb`. It handles way too much stuff! Importantly, it handles loading up a track in the `project` method. Notice how when an object is created (Button, VisualizedTrack, etc) it then usually defines a callback (like `on_change`). This is how we handle user actions like selecting part of a track (to make it our "sample") and changing slider/checkbox/drum values.
2. The rest of the code is in the `lib` directory. There are many files here but most follow a simple pattern. In `initialize` we define some properties for Ruby2D (like x, y, width, height) and then we call `add`. The `add` method handles actually rendering our element!
3. Some files handle audio processing. Check out `delay.rb`. In its `apply` method it will take a list of samples, a sample rate, and the number of channels in the audio.
