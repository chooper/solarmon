require "json"
require "excon"

module SolarEdge
  class Api

    BASE_URL = 'https://monitoringapi.solaredge.com'
    ALLOWED_TIME_UNITS = %w{QUARTER_OF_AN_HOUR HOUR DAY WEEK MONTH YEAR}

    def initialize(api_key)
      @api_key = api_key
    end

    def site_details(site_id:)
      _request('details', {
        siteId: site_id,
      })
    end

    # accept Time args
    def site_energy(site_id:, start_date:, end_date:, time_unit:)
      start_date = start_date.strftime("%Y-%m-%d")
      end_date = end_date.strftime("%Y-%m-%d")
      raise ArgumentError.new("Invalid time_unit #{time_unit.inspect}") if !ALLOWED_TIME_UNITS.include?(time_unit)

      _request('energy', {
        siteId: site_id,
        startDate: start_date,
        endDate: end_date,
        timeUnit: time_unit
      })
    end

    def _request(method, params={})
      url = if params[:siteId]
        [BASE_URL, 'site', params.delete(:siteId), "#{method}.json"].join('/')
      else
        [BASE_URL, "#{method}.json"].join('/')
      end

      params[:api_key] = @api_key
      # build request arguments
      url += '?' + params.map {|k,v| "#{k}=#{v}"}.join('&')

      response = Excon.get(url)
      body = response.body
      JSON.parse(body)
    end
  end
end
