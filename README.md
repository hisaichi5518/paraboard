# Paraboard

a scoreboard for monitoring status of many workers.

## Usage

```ruby
require 'paraboard'

para = Paraboard::Registry.new(base_dir: "/tmp/score-board")

# in each worker process
para.update("this is my current status")

# to read status of all worker processes
stats = para.read_all
stats.each do |pid, status|
  puts "pid(#{pid}) status: #{status}"
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'paraboard'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paraboard

## Contributing

1. Fork it ( https://github.com/hisaichi5518/paraboard/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
