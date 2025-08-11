json.partial! "api/v1/base"

if @data[:country]
  json.data do
    json.country do
      json.partial! "api/v1/shared/country", country: @data[:country]
    end
    json.users_count @data[:users_count]

    if @data[:restricted_content_count]
      json.restricted_content_count @data[:restricted_content_count]
    end
  end
end
