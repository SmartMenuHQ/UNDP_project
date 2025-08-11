json.partial! "api/v1/base"

if @data[:country]
  json.data do
    json.country do
      json.partial! "api/v1/shared/country", country: @data[:country]
    end
    json.statistics @data[:statistics]
  end
end
