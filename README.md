# ApiBomb
After investigating all ruby gems and commercial services for testing my API performance,
I figured out that none of those was easy to use. Most of them were not built with
APIs in mind, were difficult to create a simple test, even more tricky to add
more sophisticated requests and paid services didn't work for localhost.

All failed to my request: test and measure my API performance without spending
too much time in this shit.

So I built my own gem.
Started as a funny gist, ended up as a fully fledged gem.

ApiBomb will allow you to test how much your API can take. It will start firing
as many requests as you want for any timespan you want, all of them fully customizable.

Are you ready to defend your API?


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'api_bomb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install api_bomb

## Usage
First you need to define the global settings.
Usually in the global settings hash you just want to define the most common settings.
Options can be overrided later, if needed, per path.

```ruby
options = {
  fronts: 4, #concurrent users
  duration: 60, #seconds
  base_url: 'http://localhost:3000/api/v1', #base url
  options: { #this hash is overriden for each path that has its own options
    headers: { #various headers, like session token etc
      'Session-Token' => SESSION_TOKEN,
      'Connection' => 'close',
      'Content-Type' => 'application/json'
    },
    params: { #GET params
    },
    json: { #POST/PUT/PATCH HTTP body params
    }
  },
}
```

### Simple mode
* You want to test how many GET rpm an endpoint can hold?
```ruby
path = 'videos'
ApiBomb::War.new(options.merge({path: path})).start!
```
This will fire tons of requests in the `http://localhost:3000/api/v1/videos`
using the headers from the global settings for 60 seconds. 4 concurrent users
means that they will always be 4 requests pending from the client perspective.
As soon as one is served, a new one will be fired. Once the test duration is
elapsed it will report back to you:

```ruby
Elapsed time: 60
Concurrency: 4 threads
Number of requests: 298
Requests per second: 4
Requests per minute: 298.0
Average response time: 0.6628006505031939
Standard deviation: 0.2957473991283155
Percentile 90th: 1.0887710852002783
Percentile 95th: 1.154147314250258
Percentile 99th: 1.5413802972278787
server status stats: [{"2xx"=>298}]
```
You can also inject your logger in the global options.


* You want to test how many GET rpm a sequence of endpoints can hold? It will run
a separate benchmark for each of your endpoints.
```ruby
paths = ['videos', 'users', 'comments']
ApiBomb::War.new(options.merge({paths: paths})).start!
```
This will fire tons of requests like in the previous example,
first in `http://localhost:3000/api/v1/videos`
then in `http://localhost:3000/api/v1/users` and finally in
`http://localhost:3000/api/v1/comments`

* You want to test a POST endpoint? Then you can the slightly more advanced API:
```ruby
video_params = { title: 'A new video!', description: 'a new description!', user_id: 1}
paths = {path: 'videos', action: :post, options: { json: video_params}}
ApiBomb::War.new(options.merge({paths: paths})).start!
```

* You want to test dynamic endpoints?
```ruby
paths = {path: Proc.new{ "videos/#{1.upto(10000).to_a.sample}" } #default action is :get
ApiBomb::War.new(options.merge({paths: paths})).start!
```
You can add lambdas or (preferrably) procs in any value of the options hash and
path.

It should be noted that using lambdas/procs, it's almost endless of what you can do.
You could use FactoryGirl or whatever to get dynamic attributes when creating/updating
a resource in your API. **Be sure to watch out though, that constants and classes have already
been initialized because most of such gems do lazy initialization.**

* You want to test a sequence of endpoints with dynamic params? It will run a separate
benchmark for each one in the array.
```ruby
paths = [ #get http method is used by default
  {
    path: 'videos',
    params: { per_page: Proc.new{ 1.upto(10).to_a.sample } } #you can have a proc in a specific param only
  },
  {
    path: 'videos',
    params: { per_page: Proc.new{ 1.upto(10).to_a.sample } } #you can have a proc in a specific param only
  },
  {
    path: 'videos',
    params: { per_page: Proc.new{ 1.upto(10).to_a.sample } } #you can have a proc in a specific param only
  },
  {
    path: 'videos',
    params: { per_page: Proc.new{ 1.upto(10).to_a.sample } } #you can have a proc in a specific param only
  },
]
```

* You want to test dynamic endpoints with dynamic params?
```ruby
paths = {
  path: Proc.new{ ['videos', 'users', 'comments', 'likes'].sample,
  action: :get,
  params: Proc.new{ {per_page: 1.upto(10).to_a.sample} }
}
ApiBomb::War.new(options.merge({paths: paths})).start!
```

This is also equivelent to the previous:
```ruby
paths = {
  path: Proc.new{ ['videos', 'users', 'comments', 'likes'].sample,
  action: :get,
  params: { per_page: Proc.new{ 1.upto(10).to_a.sample } } #you can have a proc in a specific param only
}
ApiBomb::War.new(options.merge({paths: paths})).start!
```

The dynamic nature is up to you. But for your convinience we have created a special
class that can be used if you want to test random paths using a probability/weight.
So if you want for bombard 'videos' path 3 times more than comments and comments path 3 times
more users path (so videos will be bombarded 9 times more than users path) in a war (test):

```ruby
paths = ApiBomb::Path::Weighted.new({
  {path: 'videos'} => 9,
  {path: 'comments'} => 3,
  {path: 'users'} => 1,
})

ApiBomb::War.new(options.merge({paths: paths})).start!
```

or a more spophisticated:
```ruby
paths = ApiBomb::Path::Weighted.new({
  {path: 'videos', action: :get, options: { params: {per_page: 1}}} => 20,
  {path: 'videos', action: :get, options: {
    params: { per_page: Proc.new{ 1.upto(10).to_a.sample } }
  }} => 10,
  {path: Proc.new{ "videos/#{video_ids.sample}" }, action: :get} => 70,
  {path: Proc.new{ "users/#{user_ids.sample}" }, action: :get} => 60,
})

ApiBomb::War.new(options.merge({paths: paths})).start!
```

# Advanved
You can have lambdas/procs in any hash value (or key for RandomPaths). Internally
Path::Single, Path::Sequence and Path::Weighted classes are used, which you can also use
but I have ommitted them from the examples for the sake of simplicity (and added
a builder that figures out what you actually want).

You can also create your own Path structure. It only needs to respond to pick
method which must return a Path::Single object with all the necessary attributes.

Furthermore, if you like, you can override the default strategy. You might want to
dispatch a new request depending on the response of the previous request. Take
a look on `lib/api_bomb/strategies.rb`

On the global settings hash, you can also specify the number of requests you want
to send (which will override the duration unless Timeout exception kicks in first).
It's not very well tested and should be used mostly for debugging (requests: 1)

Here comes a rather advanced test:

# Best practices
* When starting optimizing, be sure that you test the performance of your API and
not of your webserver. For instance, you might fire 2 concurrent users in an
endpoint which will result in 300 req/min. Then you might fire 20 concurrent users
which could result in 450 req/min. Does it mean that your API is faster? Probably 
not because your response time must have went > 1 sec which sucks.

That's why other statistics are included apart from req/min.


## Contributing

1. Fork it ( https://github.com/vasilakisfil/api_bomb/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
