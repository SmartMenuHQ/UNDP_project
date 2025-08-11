json.partial! "api/v1/base"

if @data[:countries]
  json.data do
    json.countries @data[:countries] do |country|
      json.partial! "api/v1/shared/country", country: country
    end
    json.total_count @data[:total_count]
    json.active_count @data[:active_count]
    json.inactive_count @data[:inactive_count]
    json.regions @data[:regions]
  end
end
