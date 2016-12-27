Sequel.migration do
  change do
    add_index(:energy, [:siteID, :date, :value, :unit])
  end
end
