# -*- SkipSchemaAnnotations
module AssessmentQuestions
  class BooleanType < AssessmentQuestion
    has_many :option, class_name: "AssessmentQuestionOption", foreign_key: "assessment_question_id", dependent: :destroy

    accepts_nested_attributes_for :option, allow_destroy: true

    # Explicit attribute declaration for enum
    attribute :sub_type, :string

    # Default validation rules for BooleanType questions
    def default_validation_rule_set_for_type
      {
        "max_selections" => {
          "value" => 1,
          "message" => "validation_errors.single_selection_only",
        },
      }
    end

    # Available validation rules for BooleanType questions
    def available_validation_rules_for_type
      base_validation_rules.concat([
        "max_selections" => { name: "Maximum Selections", description: "Can select at most X options" },
      ])
    end

    after_create :create_boolean_options

    # Override to extract boolean value from response
    def extract_response_value(response)
      # For boolean questions, extract the boolean value or selected option
      if response.respond_to?(:selected_options) && response.selected_options.any?
        # If using options (Yes/No options), return the option ID
        response.selected_options.first&.assessment_question_option_id
      elsif response.value.is_a?(Hash)
        # Try different boolean field names
        response.value["boolean"] || response.value[:boolean] ||
        response.value["value"] || response.value[:value] ||
        response.value["checked"] || response.value[:checked] ||
        super
      else
        response.value
      end
    end

    private

    def create_boolean_options
      source_locale = default_locale || "en"

      # Create options with localized text in the source locale
      Mobility.with_locale(source_locale.to_sym) do
        option.create!([
          { text: I18n.t("true"), order: 1, assessment: assessment, default_locale: source_locale },
          { text: I18n.t("false"), order: 2, assessment: assessment, default_locale: source_locale },
        ])
      end
    end
  end
end
