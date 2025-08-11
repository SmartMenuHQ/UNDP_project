# app/models/rule_type.rb
class RuleType < ActiveYaml::Base
  set_root_path Rails.root.join("config")
  set_filename "rule_types"

  def self.find_by_key(key)
    find_by(key: key.to_s)
  end

  def key
    attributes[:key]
  end

  def self.all_rule_types
    all.map(&:key)
  end

  def self.applicable_for_question_type(question_type)
    all.select { |rule_type| rule_type.applicable_question_types.include?(question_type) }
  end

  def self.rule_type_keys_for_question_type(question_type)
    applicable_for_question_type(question_type).map(&:key)
  end

  def name
    attributes[:name]
  end

  def description_key
    attributes[:description_key]
  end

  def applicable_question_types
    attributes[:applicable_question_types] || []
  end

  def criteria_fields
    attributes[:criteria_fields] || []
  end

  def required_criteria_fields
    criteria_fields.select { |field| field["required"] }
  end

  def optional_criteria_fields
    criteria_fields.reject { |field| field["required"] }
  end
end
