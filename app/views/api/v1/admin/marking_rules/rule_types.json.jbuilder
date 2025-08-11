json.partial! "/api/v1/base"

json.data do
  json.rule_types @data[:rule_types]
  json.default @data[:default]
end
