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

FactoryBot.define do
  factory :assessment_response_score do
    association :assessment_question_response
    association :assessment_marking_scheme
    association :assessment_question_marking_rule

    score_earned { 75.0 }
    max_possible_score { 100.0 }
    feedback { nil }
    scoring_details { {} }

    trait :with_feedback do
      feedback { 'Good work! You demonstrated understanding of the material.' }
    end

    trait :with_detailed_scoring do
      scoring_details do
        {
          matched_criteria: ['quality_check', 'compliance_check'],
          unmatched_criteria: ['documentation_check'],
          calculation_steps: [
            'Quality assessment: 80%',
            'Compliance check: 90%',
            'Documentation review: 60%',
            'Overall score: 75%'
          ],
          rule_type: 'multi_criteria',
          criteria_applied: {
            quality: 'good',
            compliance: 'passed',
            documentation: 'incomplete'
          }
        }
      end
    end

    trait :perfect_score do
      score_earned { 100.0 }
      max_possible_score { 100.0 }
      feedback { 'Excellent work! Perfect score achieved.' }
    end

    trait :failing_score do
      score_earned { 25.0 }
      max_possible_score { 100.0 }
      feedback { 'Review the material and try again.' }
    end

    trait :import_ready do
      score_earned { 85.0 }
      max_possible_score { 100.0 }
      feedback { 'Product is ready for import!' }
      scoring_details do
        {
          import_readiness: true,
          quality_score: 90,
          compliance_score: 85,
          documentation_score: 80
        }
      end
    end

    trait :not_import_ready do
      score_earned { 35.0 }
      max_possible_score { 100.0 }
      feedback { 'Product needs improvement before import.' }
      scoring_details do
        {
          import_readiness: false,
          quality_score: 40,
          compliance_score: 30,
          documentation_score: 35
        }
      end
    end
  end
end
