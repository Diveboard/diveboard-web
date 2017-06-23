class CreateGbifIpts < ActiveRecord::Migration
  def self.up
    create_table :gbif_ipts do |t|
      t.integer :dive_id
      t.integer :eol_id
    end
    columns = ["modified", "institutionCode", "references", "catalognumber" ,"scientificnName", "basisOfRecord", "nameAccordingTo", "dateIdentified" ,"bibliographicCitation", "kingdom", "phylum", "class", "order", "family", "genus", "specificEpithet", "infraspecificEpitet", "scientificNameAuthorship", "identifiedBy", "recordedBy", "eventDate", "eventTime", "higherGeographyID", "country", "locality", "decimalLongitude", "decimallatitude", "CoordinatePrecision", "MinimumDepth", "MaximumDepth", "Temperature", "Continent", "waterBody", "eventRemarks", "fieldnotes", "locationRemarks", "type", "language", "rights", "rightsholder", "datasetID", "datasetName", "ownerintitutionCode", "countryCode", "geodeticDatim", "georeferenceSources", "minimumElevationInMeters", "maximumElevationInMeters", "taxonID", "nameAccordingToID", "taxonRankvernacularName", "occurrenceID", "associatedMedia", "eventID", "habitat"]
    columns.each do |c|
      add_column :gbif_ipts, "g_#{c}".to_sym, :string
    end

  end

  def self.down
    drop_table :gbif_ipts
  end
end
