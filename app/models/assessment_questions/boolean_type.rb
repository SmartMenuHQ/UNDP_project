# -*- SkipSchemaAnnotations
module AssessmentQuestions
  class BooleanType < AssessmentQuestion
    has_many :option, class_name: "AssessmentQuestionOption", foreign_key: "assessment_question_id", dependent: :destroy

    accepts_nested_attributes_for :option, allow_destroy: true

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
