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
  class Radio < AssessmentQuestion
    has_many :option, class_name: "AssessmentQuestionOption", foreign_key: "assessment_question_id", dependent: :destroy

    accepts_nested_attributes_for :option, allow_destroy: true

    # Explicit attribute declaration for enum
    attribute :sub_type, :string

    # Sub-types for radio button questions
    enum :sub_type, {
      radio_buttons: "radio_buttons",
      dropdown: "dropdown",
      button_group: "button_group",
      cards: "cards",
      inline: "inline",
    }

    # Validations
    validates :sub_type, presence: true
    validate :options_count_validation, unless: :new_record?

    # Default validation rules for Radio questions
    def default_validation_rule_set_for_type
      {
        "max_selections" => {
          "value" => 1,
          "message" => "validation_errors.single_selection_only",
        },
      }
    end

    # Available validation rules for Radio questions
    def available_validation_rules_for_type
      base_validation_rules.concat([
        "max_selections" => { name: "Maximum Selections", description: "Can select at most X options" },
      ])
    end

    # Set default sub_type if not specified
    after_initialize :set_default_sub_type, if: :new_record?

    # Override to extract selected option ID from response
    def extract_response_value(response)
      # For radio questions, return the selected option ID (single selection)
      if response.respond_to?(:selected_options)
        selected = response.selected_options.first
        selected&.assessment_question_option_id
      elsif response.respond_to?(:response_value)
        value = response.response_value
        value.is_a?(Array) ? value.first : value
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
      self.sub_type ||= "radio_buttons"
    end
  end
end
