# gruf-zipkin - Zipkin tracing for gruf

[![Build Status](https://travis-ci.org/bigcommerce/gruf-zipkin.svg?branch=master)](https://travis-ci.org/bigcommerce/gruf-zipkin) [![Gem Version](https://badge.fury.io/rb/gruf-zipkin.svg)](https://badge.fury.io/rb/gruf-zipkin) [![Inline docs](http://inch-ci.org/github/bigcommerce/gruf-zipkin.svg?branch=master)](http://inch-ci.org/github/bigcommerce/gruf-zipkin)

Adds Zipkin tracing support for [gruf](https://github.com/bigcommerce/gruf) 1.0.0 or later.

## Installation

```ruby
gem 'gruf-zipkin'
```

Then in an initializer or before use, after loading gruf:

```ruby
require 'zipkin-tracer'
require 'gruf/zipkin'

# Set it in the Rails config, or alternatively make this just a hash if not using Rails
Rails.application.config.zipkin_tracer = {
  service_name: 'my-service',
  service_port: 1234,
  json_api_host: 'zipkin.mydomain.com',
  sampled_as_boolean: false,
  sample_rate: 0.1 # 0.0 to 1.0, where 1.0 => 100% of requests 
}
Gruf.configure do |c|
  c.hook_options[:zipkin] = Rails.application.config.zipkin_tracer
end
Gruf::Hooks::Registry.add(:zipkin, Gruf::Zipkin::Hook)
```

This assumes you have Zipkin already setup in your Ruby/Rails app via the installation 
instructions in the [zipkin-tracer](https://github.com/openzipkin/zipkin-ruby) gem.

### Rails/Rack Tracing

Add this to config.ru, if using above configuration:
 
```ruby
use ZipkinTracer::RackHandler, Rails.application.config.zipkin_tracer
```

## Configuration

You can further customize the tracing of gruf services via the configuration:

```ruby
Gruf.configure do |c|
  c.hook_options[:zipkin] = {
    span_prefix: 'myapp'
  }
end
```

## License

Copyright (c) 2017-present, BigCommerce Pty. Ltd. All rights reserved 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the 
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit 
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the 
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
