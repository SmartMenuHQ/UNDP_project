json.partial! "/api/v1/base"

if @data[:marking_schemes]
  json.data do
    json.marking_schemes @data[:marking_schemes] do |scheme|
      json.partial! "api/v1/admin/marking_schemes/marking_scheme", marking_scheme: scheme
    end
    json.total_count @data[:total_count]
    json.active_count @data[:active_count]
    json.pagination @data[:pagination]
    json.assessment @data[:assessment]
  end
end
