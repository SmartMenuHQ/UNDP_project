json.partial! "/api/v1/base"

if @data[:marking_scheme]
  json.data do
    json.marking_scheme do
      json.partial! "api/v1/admin/marking_schemes/marking_scheme", marking_scheme: @data[:marking_scheme]
    end
  end
end
