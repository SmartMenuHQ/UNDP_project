json.partial! "/api/v1/base"

if @data[:marking_rule]
  json.data do
    json.marking_rule do
      json.partial! "api/v1/admin/marking_rules/marking_rule", marking_rule: @data[:marking_rule]
    end
  end
end
