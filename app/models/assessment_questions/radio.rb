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
