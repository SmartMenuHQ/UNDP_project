json.partial! "/api/v1/base"

if @data[:marking_rules]
  json.data do
    json.marking_rules @data[:marking_rules] do |rule|
      json.partial! "api/v1/admin/marking_rules/marking_rule", marking_rule: rule
    end
    json.total_count @data[:total_count]
    json.active_count @data[:active_count]
    json.pagination @data[:pagination]
    json.assessment @data[:assessment]
    json.marking_scheme @data[:marking_scheme]
  end
end
