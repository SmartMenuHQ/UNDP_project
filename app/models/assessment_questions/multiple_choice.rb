# -*- SkipSchemaAnnotations
module AssessmentQuestions
  class MultipleChoice < AssessmentQuestion
    has_many :option, class_name: 'AssessmentQuestionOption', foreign_key: 'assessment_question_id', dependent: :destroy

    accepts_nested_attributes_for :option, allow_destroy: true

    validate :options_count_validation, unless: :new_record?

    private

    def options_count_validation
      if option.reject(&:marked_for_destruction?).size < 2
        errors.add(:option, "must have at least 2 options")
      end
    end
  end
end
