json.partial! "/api/v1/base"

json.data do
  json.created_count @data[:created_count]
  json.marking_rules @data[:marking_rules] do |rule|
    json.partial! "api/v1/admin/marking_rules/marking_rule", marking_rule: rule
  end
end
