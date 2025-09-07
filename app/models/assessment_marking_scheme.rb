# == Schema Information
#
# Table name: assessment_marking_schemes
#
#  id                   :bigint           not null, primary key
#  description          :text
#  is_active            :boolean          default(TRUE)
#  name                 :string           not null
#  settings             :jsonb
#  total_possible_score :decimal(10, 2)   default(0.0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  assessment_id        :bigint           not null
#
# Indexes
#
#  index_assessment_marking_schemes_on_assessment_id  (assessment_id)
#  index_assessment_marking_schemes_on_is_active      (is_active)
#  index_assessment_marking_schemes_on_name           (name)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#
class AssessmentMarkingScheme < ApplicationRecord
  belongs_to :assessment
  has_many :assessment_question_marking_rules, dependent: :destroy
  has_many :assessment_questions, through: :assessment_question_marking_rules
  has_many :assessment_response_scores, dependent: :destroy

  validates :name, presence: true
  validates :total_possible_score, numericality: { greater_than_or_equal_to: 0 }

  store_accessor :settings, :passing_score, :grade_boundaries, :feedback_templates

  scope :active, -> { where(is_active: true) }

  def calculate_total_score_for_assessment(assessment_id)
    responses = AssessmentQuestionResponse.where(assessment_id: assessment_id)
    total_score = 0
    total_possible = 0

    responses.each do |response|
      score = grade_response(response)
      total_score += score.score_earned
      total_possible += score.max_possible_score
    end

    {
      total_score: total_score,
      total_possible: total_possible,
      percentage: calculate_percentage(total_score, total_possible),
      grade: calculate_grade(total_score, total_possible),
    }
  end

  def grade_response(response)
    rules = response.assessment_question.assessment_question_marking_rules
                    .where(assessment_marking_scheme: self)
                    .active
                    .ordered

    best_score = 0
    best_rule = rules.first # Use first rule as default for max possible score

    rules.each do |rule|
      score = rule.evaluate_response(response)
      if score > best_score
        best_score = score
        best_rule = rule
      end
    end

    # If no rule scored above 0, still use the first rule for max possible score
    create_response_score(response, best_rule, best_score)
  end

  def passing_score_percentage
    return 0 unless passing_score.present?
    (passing_score.to_f / total_possible_score * 100).round(2)
  end

  private

  def calculate_percentage(score, total)
    return 0 if total.zero?
    (score.to_f / total * 100).round(2)
  end

  def calculate_grade(score, total)
    percentage = calculate_percentage(score, total)

    grade_boundaries&.each do |grade, threshold|
      return grade if percentage >= threshold
    end

    "F"
  end

  def create_response_score(response, rule, score_earned)
    AssessmentResponseScore.create!(
      assessment_question_response: response,
      assessment_marking_scheme: self,
      assessment_question_marking_rule: rule,
      score_earned: score_earned,
      max_possible_score: rule&.points || 0,
      scoring_details: {
        rule_type: rule&.rule_type,
        criteria_applied: rule&.criteria,
      },
    )
  end
end
