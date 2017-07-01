require "sequel"
require "logger"
require "pg"

module SolarEdge::Storage
  def self.connect_database
    url = ENV['DATABASE_URL'] || 'sqlite://db.sqlite'
    max_conns = (ENV['SQL_CONNS'] || 1).to_i

    Sequel.default_timezone = :utc
    db = Sequel.connect(url, max_connections: max_conns, loggers: [Logger.new($stdout)])
    log_level = ENV['SQL_DEBUG'] || 'debug'
    log_level = log_level.downcase.to_sym
    db.sql_log_level = log_level
    db
  end

  def self.create_database_tables!(db)
    create_energy_table!(db)
  end

  def self.create_energy_table!(db)
    db.create_table :energy do
      primary_key :ID
      Integer     :siteID
      Time        :date
      Float       :value
      String      :unit
      unique      [:siteID, :date]
    end
    true
  rescue Sequel::DatabaseError, PG::DuplicateTable
    # table probably already existed
    # TODO(charles) log this
    false
  end

  def self.save_energy_value(db, siteID:, date:, value:, unit:)
    db[:energy].insert_conflict(target: [:siteID, :date], update: {value: value, unit: unit}).insert({
      siteID: siteID,
      date: date,
      value: value,
      unit: unit,
    })
  end

  def self.get_energy_values(db, where, opts={})
    limit = opts[:limit] || 20_000
    db.from(:energy).select(:siteID, :date, :value, :unit).where(where).order(:date).limit(limit)
  end

  def self.count_energy_values(db, where)
    self.get_energy_values(db, where, limit: 1).count
  end

  def self.energy_value_exists?(db, key)
    self.count_energy_values(db, key) > 0
  end
end
