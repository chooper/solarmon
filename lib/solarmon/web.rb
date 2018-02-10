require 'json'
require 'sinatra/base'
require 'solarmon/version'

module SolarMon::Web
  class Application < Sinatra::Base
    set :sessions, false
    enable :logging

    get '/' do
      erb :index
    end

    get '/version' do
      "SolarMon #{SolarMon::VERSION}"
    end

    get '/health' do
      content_type :json
      date = Time.now.getutc.to_date
      date_range = (date - 1)..(date + 1)

      db = SolarMon::Storage.connect_database
      values = SolarMon::Storage.get_energy_values(db, {date: date_range})

      # find the most recent data point and ensure it's < 12 hours old
      value = values.sort_by {|v| v[:date]}.last
      if value[:date] < Time.now - 60*60*12
        halt 500, {status: 'FAIL', msg: 'data is not fresh', most_recent_value: value}.to_json
      end

      SolarMon::Storage.disconnect_database(db)
      {status: 'OK', most_recent_value: value}.to_json
    end

    get '/energy.json' do
      content_type :json
      date = Time.now.getutc.to_date
      date_range = (date - 90)..(date + 1)

      db = SolarMon::Storage.connect_database
      values = SolarMon::Storage.get_energy_values(db, {date: date_range})

      presentable_values = values.map {|r| {
        siteID: r[:siteID],
        date: r[:date].strftime("%Y-%m-%d %H:%M:%S %z"),
        value: r[:value],
        unit: r[:unit],
      }}

      SolarMon::Storage.disconnect_database(db)
      {energy: presentable_values}.to_json
    end
  end
end
