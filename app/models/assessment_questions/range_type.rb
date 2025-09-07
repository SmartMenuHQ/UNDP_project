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
  class RangeType < AssessmentQuestion
    # Explicit attribute declaration for enum
    attribute :sub_type, :string

    # Sub-types for range/numeric questions
    enum :sub_type, {
      slider: "slider",
      number_input: "number_input",
      rating: "rating",
      scale: "scale",
      spinner: "spinner",
      progress: "progress",
      range: "range",
    }

    # Validations
    validates :sub_type, presence: true

    # Default validation rules based on sub_type
    def default_validation_rule_set_for_type
      rules = {}

      case sub_type
      when "rating"
        # Default rating scale 1-5
        rules["number_range"] = {
          "min" => 1,
          "max" => 5,
          "message" => "default_rules.rating_scale",
        }
      when "slider", "progress"
        # Default range 0-100
        rules["number_range"] = {
          "min" => 0,
          "max" => 100,
          "message" => "default_rules.slider_range",
        }
      when "spinner", "number_input"
        # Default positive numbers
        rules["number_range"] = {
          "min" => 0,
          "message" => "default_rules.positive_number",
        }
      when "range"
        # Range type needs both min and max values
      end

      rules
    end

    # Available validation rules for RangeType questions
    def available_validation_rules_for_type
      base_validation_rules.concat([
        "number_range" => { name: "Number Range", description: "Value must be within specified range" },
        "integer_only" => { name: "Integer Only", description: "Value must be a whole number" },
      ])
    end

    # Set default sub_type if not specified
    after_initialize :set_default_sub_type, if: :new_record?

    # Default range values
    def min_value
      meta_data&.dig("min_value") || 1
    end

    def max_value
      meta_data&.dig("max_value") || 10
    end

    def step_value
      meta_data&.dig("step_value") || 1
    end

    # Override to extract numeric value from response
    def extract_response_value(response)
      return response.value unless response.value.is_a?(Hash)

      # For range/numeric questions, try different numeric field names
      response.value["number"] || response.value[:number] ||
      response.value["rating"] || response.value[:rating] ||
      response.value["range"] || response.value[:range] ||
      response.value["value"] || response.value[:value] ||
      super
    end

    private

    def set_default_sub_type
      self.sub_type ||= "slider"
    end
  end
end
