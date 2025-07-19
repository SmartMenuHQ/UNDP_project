# == Schema Information
#
# Table name: selected_options
#
#  id                               :bigint           not null, primary key
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  assessment_question_response_id  :bigint           not null
#  assessment_question_option_id    :bigint           not null
#
# Indexes
#
#  index_selected_options_on_assessment_question_option_id    (assessment_question_option_id)
#  index_selected_options_on_assessment_question_response_id  (assessment_question_response_id)
#  index_selected_options_unique                              (assessment_question_response_id,assessment_question_option_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (assessment_question_option_id => assessment_question_options.id)
#  fk_rails_...  (assessment_question_response_id => assessment_question_responses.id)
#
class SelectedOption < ApplicationRecord
  belongs_to :assessment_question_response
  belongs_to :assessment_question_option

  # Validations
  validates :assessment_question_response_id, uniqueness: {
    scope: :assessment_question_option_id,
    message: "Option can only be selected once per response"
  }

  validate :validate_option_belongs_to_question
  validate :validate_selection_constraints

  # Scopes
  scope :for_question, ->(question_id) {
    joins(:assessment_question_option)
      .where(assessment_question_options: { assessment_question_id: question_id })
  }

  scope :for_response, ->(response_id) {
    where(assessment_question_response_id: response_id)
  }

  private

  def validate_option_belongs_to_question
    return unless assessment_question_response && assessment_question_option

    unless assessment_question_option.assessment_question_id == assessment_question_response.assessment_question_id
      errors.add(:assessment_question_option, "must belong to the same question as the response")
    end
  end

  def validate_selection_constraints
    return unless assessment_question_response&.assessment_question

    question = assessment_question_response.assessment_question
    existing_selections = assessment_question_response.selected_options.where.not(id: id)

    case question.type
    when 'AssessmentQuestions::Radio', 'AssessmentQuestions::BooleanType'
      if existing_selections.exists?
        errors.add(:base, "Only one option can be selected for #{question.question_type_name.downcase} questions")
      end
    when 'AssessmentQuestions::MultipleChoice'
      # Multiple selections allowed, no additional validation needed
    end
  end
end
