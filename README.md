# SolarEdge
This is some code I use to poke at my solar system's monitoring API.

API docs are available at
http://www.solaredge.com/sites/default/files/se_monitoring_api.pdf

Currently the only thing I really do with this is sync my measured energy
production to a postgres database on Heroku.

## Setting the syncer up on Heroku
```bash
$ heroku create -a cch-solar
$ heroku addons:add scheduler:standard
$ heroku addons:open scheduler # Add `./bin/energy2pg`
$ heroku config:set SOLAREDGE_API_KEY=...
$ heroku config:set SOLAREDGE_SITE_ID=...
$ heroku addons:add heroku-postgresql:hobby-basic
$ git push heroku master
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'solaredge'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install solaredge

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/solaredge. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
