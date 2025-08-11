json.partial! "/api/v1/base"

if @data[:section]
  json.data do
    json.section do
      json.partial! "api/v1/shared/assessment_section", section: @data[:section]
    end
  end
end
