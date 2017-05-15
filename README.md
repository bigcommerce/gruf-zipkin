# gruf-zipkin - Zipkin tracing for gruf

[![Build Status](https://travis-ci.com/bigcommerce/gruf-zipkin.svg?token=D3Cc4LCF9BgpUx4dpPpv&branch=master)](https://travis-ci.com/bigcommerce/gruf-zipkin)

Adds Zipkin tracing support for [gruf](https://github.com/bigcommerce/gruf) 0.11.5 or later.

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
  sample_rate: 1.0 # 0.0 to 1.0, where 1.0 => 100% of requests 
}
Gruf.configure do |c|
  c.hook_options = {
    zipkin: Rails.application.config.zipkin_tracer
  }
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
  c.hook_options = {
    zipkin: {
      span_prefix: 'myapp',
    }
  }
end
```

## License

Copyright 2017, Bigcommerce Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following disclaimer
in the documentation and/or other materials provided with the
distribution.
* Neither the name of BigCommerce Inc. nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
