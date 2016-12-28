require "sequel"
require "logger"
require "pg"

module SolarEdge::Storage
  def self.connect_database
    Sequel.default_timezone = :utc
    url = ENV['DATABASE_URL'] || 'sqlite://db.sqlite'
    db = Sequel.connect(url, loggers: [Logger.new($stdout)])
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

  def self.get_energy_values(db, where)
    db.from(:energy).where(where).order(:date).limit(20_000)
  end
end
