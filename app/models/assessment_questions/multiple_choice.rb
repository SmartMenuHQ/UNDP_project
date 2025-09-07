# -*- SkipSchemaAnnotations
module AssessmentQuestions
  class MultipleChoice < AssessmentQuestion
    has_many :option, class_name: "AssessmentQuestionOption", foreign_key: "assessment_question_id", dependent: :destroy

    accepts_nested_attributes_for :option, allow_destroy: true

    # Explicit attribute declaration for enum
    attribute :sub_type, :string

    # Sub-types for multiple choice questions
    enum :sub_type, {
      checkboxes: "checkboxes",
      dropdown: "dropdown",
      tags: "tags",
    }

    # Validations
    validates :sub_type, presence: true
    validate :options_count_validation, unless: :new_record?

    # Default validation rules for MultipleChoice questions
    def default_validation_rule_set_for_type
      {
        "min_selections" => {
          "value" => 1,
          "message" => "validation_errors.required",
        },
      }
    end

    # Available validation rules for MultipleChoice questions
    def available_validation_rules_for_type
      base_validation_rules.concat([
        "min_selections" => { name: "Minimum Selections", description: "Must select at least X options" },
        "max_selections" => { name: "Maximum Selections", description: "Can select at most X options" },
      ])
    end

    # Set default sub_type if not specified
    after_initialize :set_default_sub_type, if: :new_record?

    # Override to extract selected option IDs from response
    def extract_response_value(response)
      # For choice questions, return the selected option IDs
      # This is handled differently since options are in a separate table
      if response.respond_to?(:selected_options)
        response.selected_options.pluck(:assessment_question_option_id)
      elsif response.respond_to?(:response_value)
        response.response_value
      else
        super
      end
    end

    private

    def options_count_validation
      if option.reject(&:marked_for_destruction?).size < 2
        errors.add(:option, "must have at least 2 options")
      end
    end

    def set_default_sub_type
      self.sub_type ||= "checkboxes"
    end
  end
end
