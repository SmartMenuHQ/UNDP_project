# == Schema Information
#
# Table name: assessment_response_scores
#
#  id                                  :bigint           not null, primary key
#  feedback                            :text
#  max_possible_score                  :decimal(10, 2)   default(0.0)
#  score_earned                        :decimal(10, 2)   default(0.0)
#  scoring_details                     :jsonb
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  assessment_marking_scheme_id        :bigint           not null
#  assessment_question_marking_rule_id :bigint           not null
#  assessment_question_response_id     :bigint           not null
#
# Indexes
#
#  idx_on_assessment_marking_scheme_id_2772f2d268          (assessment_marking_scheme_id)
#  idx_on_assessment_question_marking_rule_id_e720f6ab10   (assessment_question_marking_rule_id)
#  idx_on_assessment_question_response_id_bd971c83ee       (assessment_question_response_id)
#  index_assessment_response_scores_on_max_possible_score  (max_possible_score)
#  index_assessment_response_scores_on_score_earned        (score_earned)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_marking_scheme_id => assessment_marking_schemes.id)
#  fk_rails_...  (assessment_question_marking_rule_id => assessment_question_marking_rules.id)
#  fk_rails_...  (assessment_question_response_id => assessment_question_responses.id)
#
class AssessmentResponseScore < ApplicationRecord
  belongs_to :assessment_question_response
  belongs_to :assessment_marking_scheme
  belongs_to :assessment_question_marking_rule

  validates :score_earned, numericality: { greater_than_or_equal_to: 0 }
  validates :max_possible_score, numericality: { greater_than_or_equal_to: 0 }

  store_accessor :scoring_details, :matched_criteria, :unmatched_criteria, :calculation_steps, :rule_type, :criteria_applied

  def percentage_score
    return 0 if max_possible_score.zero?
    (score_earned / max_possible_score * 100).round(2)
  end

  def passed?
    percentage_score >= assessment_marking_scheme.passing_score_percentage
  end

  def grade
    percentage = percentage_score

    grade_boundaries = assessment_marking_scheme.grade_boundaries || {}
    grade_boundaries.each do |grade, threshold|
      return grade if percentage >= threshold
    end

    "F"
  end

  def feedback_message
    feedback.presence || generate_default_feedback
  end

  private

  def generate_default_feedback
    if passed?
      "Good work! You scored #{percentage_score}% on this question."
    else
      "You scored #{percentage_score}% on this question. Review the material and try again."
    end
  end
end
