require 'sinatra/base'
require 'solaredge/version'

module SolarEdge::Web
  class Application < Sinatra::Base
    set :sessions, false

    get '/' do
      "SolarEdge #{SolarEdge::VERSION}"
    end
  end
end
