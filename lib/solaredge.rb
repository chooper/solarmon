module SolarEdge; end

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
    end

    attr_reader :site_id

    def sync!
      connect_database
      energy_values, energy_unit = get_energy_values_from_api
      save_values_to_database(energy_values, energy_unit)
    end

    def get_energy_values_from_api
      puts "Getting energy values from API"
      t = Time.now
      response = @api.site_energy(site_id: site_id,
        start_date: t,
        end_date: t,
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

      @db.transaction do
        values.map do |v|
          save_value_to_database(v, unit)
        end
      end

      puts "Saved #{values.length} records to database"
      true
    end

    def save_value_to_database(value, unit)
      raise "Connect to the database prior to calling this method!" if !@db
      raise ArgumentError.new("Got unexpected unit! #{unit.inspect}") if unit != EXPECTED_UNIT

      record = {
        siteID: site_id,
        date: value["date"],
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
