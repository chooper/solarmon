require 'json'
require 'sinatra/base'
require 'solaredge/version'

module SolarEdge::Web
  class Application < Sinatra::Base
    set :sessions, false

    get '/' do
      "SolarEdge #{SolarEdge::VERSION}"
    end

    get '/energy.json' do
      content_type :json
      date = Time.now.getutc.to_date
      date_range = (date - 90)..(date + 1)

      db = SolarEdge::Storage.connect_database
      values = SolarEdge::Storage.get_energy_values(db, {date: date_range})
      # strip the primary key from the values
      presentable_values = values.map {|r| {siteID: r[:siteID], date: r[:date], value: r[:value], unit: r[:unit]}}
      {energy: presentable_values}.to_json
    end
  end
end
