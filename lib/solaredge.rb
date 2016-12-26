module SolarEdge; end

require 'tzinfo'
require "solaredge/api"
require "solaredge/storage"
require "solaredge/version"

# TODO(charles) replace puts with logging

module SolarEdge
  class SyncMachine

    EXPECTED_UNIT = 'Wh'

    def initialize(site_id, api_key)
      @site_id = site_id
      @api = SolarEdge::Api.new(api_key)
      @tz = TZInfo::Timezone.get(ENV['TZ'])
      # HACK(charles) Figure out if we're PST vs PDT
      @tz_name = @tz.offsets_up_to(Time.now.getutc, Time.now.getutc - 1).first.abbreviation.to_s
    end

    attr_reader :site_id, :tz, :tz_name

    def sync!
      connect_database
      energy_values, energy_unit = get_energy_values_from_api
      save_values_to_database(energy_values, energy_unit)
    end

    def get_energy_values_from_api(start_date: nil, end_date: nil)
      puts "Getting energy values from API"
      start_date ||= tz.now
      end_date   ||= tz.now
      response = @api.site_energy(site_id: site_id,
        start_date: start_date,
        end_date: end_date,
        time_unit: "QUARTER_OF_AN_HOUR")

      unit = response.fetch("energy").fetch("unit")
      values = response.fetch("energy").fetch("values").reject {|e| e["value"].nil? }
      puts "Received #{values.length} non-nil values"
      [values, unit]
    end

    def save_values_to_database(values, unit)
      puts "Saving values to database"
      raise "Connect to the database prior to calling this method!" if !@db
      raise ArgumentError.new("Got unexpected unit! #{unit.inspect}") if unit != EXPECTED_UNIT

      values.map do |v|
        save_value_to_database(v, unit)
      end

      puts "Saved #{values.length} records to database"
      true
    end

    def save_value_to_database(value, unit)
      raise "Connect to the database prior to calling this method!" if !@db
      raise ArgumentError.new("Got unexpected unit! #{unit.inspect}") if unit != EXPECTED_UNIT

      record = {
        siteID: site_id,
        date: tz.local_to_utc(Time.parse("#{value["date"]} #{tz_name}")),
        value: value["value"],
        unit: unit}

      @db[:energy].insert(record)
    rescue PG::UniqueViolation, Sequel::UniqueConstraintViolation
      nil
    end

    def connect_database
      puts "Connecting to database"
      @db = SolarEdge::Storage.connect_database
      SolarEdge::Storage.create_database_tables!(@db)
      @db
    end
  end
end
