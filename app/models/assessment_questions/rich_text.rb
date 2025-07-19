# == Schema Information
#
# Table name: assessment_questions
#
#  id                     :bigint           not null, primary key
#  active                 :boolean          default(TRUE)
#  default_locale         :string
#  is_required            :boolean          default(FALSE)
#  meta_data              :jsonb
#  options_json           :jsonb
#  order                  :integer
#  text                   :text
#  type                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  assessment_sections_id :bigint
#  assessments_id         :bigint
#
# Indexes
#
#  index_assessment_questions_on_assessment_sections_id  (assessment_sections_id)
#  index_assessment_questions_on_assessments_id          (assessments_id)
#
# -*- SkipSchemaAnnotations
module AssessmentQuestions
  class RichText < AssessmentQuestion
    # Sub-types for text questions
    enum :sub_type, {
      short_text: "short_text",
      long_text: "long_text",
      rich_text: "rich_text",
      email: "email",
      url: "url",
      password: "password",
      phone: "phone",
      search: "search",
    }

    # Validations
    validates :sub_type, presence: true
    # Note: The format validations for email/url should apply to user responses, not question text

    # Default validation rules based on sub_type
    def default_validation_rule_set_for_type
      rules = {}

      case sub_type
      when "email"
        rules["email_format"] = { "message" => "default_rules.email_validation" }
      when "url"
        rules["url_format"] = { "message" => "default_rules.url_validation" }
      when "short_text"
        rules["max_length"] = { "value" => 255, "message" => "default_rules.short_text_limit" }
      when "phone"
        rules["min_length"] = { "value" => 10, "message" => "default_rules.phone_min_length" }
      when "password"
        rules["min_length"] = { "value" => 8, "message" => "default_rules.password_min_length" }
      end

      rules
    end

    # Available validation rules for RichText questions
    def available_validation_rules_for_type
      base_validation_rules.concat([
        "min_length" => { name: "Minimum Length", description: "Text must be at least X characters" },
        "max_length" => { name: "Maximum Length", description: "Text must be no more than X characters" },
        "email_format" => { name: "Email Format", description: "Must be a valid email address" },
        "url_format" => { name: "URL Format", description: "Must be a valid URL" },
        "regex_pattern" => { name: "Pattern Match", description: "Text must match a specific pattern" },
      ])
    end

    # Set default sub_type if not specified
    after_initialize :set_default_sub_type, if: :new_record?

    private

    def set_default_sub_type
      self.sub_type ||= "long_text"
    end
  end
end
