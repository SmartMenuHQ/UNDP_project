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

require 'rails_helper'

RSpec.describe AssessmentResponseScore, type: :model do
  let(:assessment) { create(:assessment) }
  let(:section) { create(:assessment_section, assessment: assessment) }
  let(:question) { create(:assessment_question, assessment_section: section, is_required: false) }
  let(:session) { create(:assessment_response_session, assessment: assessment) }
  let(:response) { create(:assessment_question_response, assessment_response_session: session, assessment_question: question, assessment: assessment) }
  let(:marking_scheme) { create(:assessment_marking_scheme, assessment: assessment) }
  let(:marking_rule) { create(:assessment_question_marking_rule, assessment_marking_scheme: marking_scheme, assessment_question: question) }

  let(:response_score) do
    create(:assessment_response_score,
      assessment_question_response: response,
      assessment_marking_scheme: marking_scheme,
      assessment_question_marking_rule: marking_rule,
      score_earned: 80.0,
      max_possible_score: 100.0
    )
  end

  describe 'associations' do
    it { should belong_to(:assessment_question_response) }
    it { should belong_to(:assessment_marking_scheme) }
    it { should belong_to(:assessment_question_marking_rule) }
  end

  describe 'validations' do
    it { should validate_numericality_of(:score_earned).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:max_possible_score).is_greater_than_or_equal_to(0) }
  end

  describe 'store_accessor scoring_details' do
    it 'allows setting and getting scoring details' do
      details = {
        matched_criteria: ['quality_check', 'compliance_check'],
        unmatched_criteria: ['documentation_check'],
        calculation_steps: ['Step 1: Quality assessment', 'Step 2: Compliance check'],
        rule_type: 'multi_criteria',
        criteria_applied: { quality: 'high', compliance: 'passed' }
      }

      response_score.update!(scoring_details: details)
      response_score.reload

      expect(response_score.matched_criteria).to eq(['quality_check', 'compliance_check'])
      expect(response_score.unmatched_criteria).to eq(['documentation_check'])
      expect(response_score.calculation_steps).to eq(['Step 1: Quality assessment', 'Step 2: Compliance check'])
      expect(response_score.rule_type).to eq('multi_criteria')
      expect(response_score.criteria_applied).to eq({ 'quality' => 'high', 'compliance' => 'passed' })
    end
  end

  describe '#percentage_score' do
    it 'calculates percentage correctly' do
      response_score.update!(score_earned: 75.0, max_possible_score: 100.0)
      expect(response_score.percentage_score).to eq(75.0)
    end

    it 'handles decimal calculations' do
      response_score.update!(score_earned: 33.33, max_possible_score: 100.0)
      expect(response_score.percentage_score).to eq(33.33)
    end

    it 'returns 0 when max_possible_score is zero' do
      response_score.update!(score_earned: 50.0, max_possible_score: 0.0)
      expect(response_score.percentage_score).to eq(0.0)
    end

    it 'rounds to 2 decimal places' do
      response_score.update!(score_earned: 33.333333, max_possible_score: 100.0)
      expect(response_score.percentage_score).to eq(33.33)
    end
  end

  describe '#passed?' do
    before do
      marking_scheme.update!(passing_score: 60.0, total_possible_score: 100.0)
    end

    context 'when score meets or exceeds passing percentage' do
      it 'returns true for exact passing score' do
        response_score.update!(score_earned: 60.0, max_possible_score: 100.0)
        expect(response_score.passed?).to be true
      end

      it 'returns true for score above passing threshold' do
        response_score.update!(score_earned: 85.0, max_possible_score: 100.0)
        expect(response_score.passed?).to be true
      end
    end

    context 'when score is below passing percentage' do
      it 'returns false' do
        response_score.update!(score_earned: 45.0, max_possible_score: 100.0)
        expect(response_score.passed?).to be false
      end
    end
  end

  describe '#grade' do
    before do
      marking_scheme.update!(
        grade_boundaries: {
          'Import Ready - Premium' => 90,
          'Import Ready - Standard' => 75,
          'Import Ready - Basic' => 50,
          'Conditional Import' => 25,
          'Not Import Ready' => 0
        }
      )
    end

    it 'returns correct grade for premium import ready score' do
      response_score.update!(score_earned: 95.0, max_possible_score: 100.0)
      expect(response_score.grade).to eq('Import Ready - Premium')
    end

    it 'returns correct grade for standard import ready score' do
      response_score.update!(score_earned: 80.0, max_possible_score: 100.0)
      expect(response_score.grade).to eq('Import Ready - Standard')
    end

    it 'returns correct grade for basic import ready score' do
      response_score.update!(score_earned: 60.0, max_possible_score: 100.0)
      expect(response_score.grade).to eq('Import Ready - Basic')
    end

    it 'returns correct grade for conditional import score' do
      response_score.update!(score_earned: 40.0, max_possible_score: 100.0)
      expect(response_score.grade).to eq('Conditional Import')
    end

    it 'returns correct grade for not import ready score' do
      response_score.update!(score_earned: 15.0, max_possible_score: 100.0)
      expect(response_score.grade).to eq('Not Import Ready')
    end

    it 'returns F when no grade boundaries match' do
      marking_scheme.update!(grade_boundaries: {})
      response_score.update!(score_earned: 85.0, max_possible_score: 100.0)
      expect(response_score.grade).to eq('F')
    end

    it 'handles boundary conditions correctly' do
      # Test exact boundary values
      response_score.update!(score_earned: 50.0, max_possible_score: 100.0)
      expect(response_score.grade).to eq('Import Ready - Basic')

      response_score.update!(score_earned: 49.9, max_possible_score: 100.0)
      expect(response_score.grade).to eq('Conditional Import')
    end
  end

  describe '#feedback_message' do
    context 'when custom feedback is provided' do
      it 'returns the custom feedback' do
        response_score.update!(feedback: 'Excellent work on this assessment!')
        expect(response_score.feedback_message).to eq('Excellent work on this assessment!')
      end
    end

    context 'when no custom feedback is provided' do
      before do
        marking_scheme.update!(passing_score: 60.0, total_possible_score: 100.0)
      end

      it 'generates positive default feedback for passing scores' do
        response_score.update!(score_earned: 75.0, max_possible_score: 100.0, feedback: nil)
        expect(response_score.feedback_message).to eq('Good work! You scored 75.0% on this question.')
      end

      it 'generates improvement feedback for failing scores' do
        response_score.update!(score_earned: 45.0, max_possible_score: 100.0, feedback: nil)
        expect(response_score.feedback_message).to eq('You scored 45.0% on this question. Review the material and try again.')
      end
    end
  end

  describe 'dynamic grading scenarios' do
    describe 'import readiness scoring' do
      before do
        marking_scheme.update!(
          name: 'Product Import Readiness',
          passing_score: 50.0,
          total_possible_score: 100.0,
          grade_boundaries: {
            'Import Ready' => 50,
            'Not Import Ready' => 0
          }
        )
      end

      context 'quality assessment scenarios' do
        it 'handles high quality product (import ready)' do
          response_score.update!(
            score_earned: 85.0,
            max_possible_score: 100.0,
            scoring_details: {
              matched_criteria: ['quality_excellent', 'compliance_passed', 'documentation_complete'],
              rule_type: 'multi_criteria_assessment',
              criteria_applied: {
                quality_score: 90,
                compliance_score: 85,
                documentation_score: 80
              }
            }
          )

          expect(response_score.percentage_score).to eq(85.0)
          expect(response_score.grade).to eq('Import Ready')
          expect(response_score.passed?).to be true
        end

        it 'handles borderline quality product (barely import ready)' do
          response_score.update!(
            score_earned: 50.0,
            max_possible_score: 100.0,
            scoring_details: {
              matched_criteria: ['compliance_passed'],
              unmatched_criteria: ['quality_excellent', 'documentation_complete'],
              rule_type: 'multi_criteria_assessment',
              criteria_applied: {
                quality_score: 45,
                compliance_score: 55,
                documentation_score: 50
              }
            }
          )

          expect(response_score.percentage_score).to eq(50.0)
          expect(response_score.grade).to eq('Import Ready')
          expect(response_score.passed?).to be true
        end

        it 'handles poor quality product (not import ready)' do
          response_score.update!(
            score_earned: 25.0,
            max_possible_score: 100.0,
            scoring_details: {
              matched_criteria: [],
              unmatched_criteria: ['quality_excellent', 'compliance_passed', 'documentation_complete'],
              rule_type: 'multi_criteria_assessment',
              criteria_applied: {
                quality_score: 30,
                compliance_score: 25,
                documentation_score: 20
              }
            }
          )

          expect(response_score.percentage_score).to eq(25.0)
          expect(response_score.grade).to eq('Not Import Ready')
          expect(response_score.passed?).to be false
        end
      end

      context 'compliance-based scoring' do
        it 'handles full compliance (import ready)' do
          response_score.update!(
            score_earned: 95.0,
            max_possible_score: 100.0,
            scoring_details: {
              matched_criteria: [
                'safety_standards_met',
                'labeling_compliant',
                'materials_approved',
                'testing_certificates_valid'
              ],
              rule_type: 'compliance_checklist',
              criteria_applied: {
                safety_compliance: 100,
                labeling_compliance: 95,
                materials_compliance: 90,
                testing_compliance: 100
              }
            }
          )

          expect(response_score.percentage_score).to eq(95.0)
          expect(response_score.grade).to eq('Import Ready')
          expect(response_score.passed?).to be true
        end

        it 'handles partial compliance (conditional import)' do
          # Set up conditional import grade
          marking_scheme.update!(
            grade_boundaries: {
              'Import Ready' => 80,
              'Conditional Import' => 50,
              'Not Import Ready' => 0
            }
          )

          response_score.update!(
            score_earned: 65.0,
            max_possible_score: 100.0,
            scoring_details: {
              matched_criteria: ['safety_standards_met', 'testing_certificates_valid'],
              unmatched_criteria: ['labeling_compliant', 'materials_approved'],
              rule_type: 'compliance_checklist',
              criteria_applied: {
                safety_compliance: 100,
                labeling_compliance: 40,
                materials_compliance: 30,
                testing_compliance: 90
              }
            }
          )

          expect(response_score.percentage_score).to eq(65.0)
          expect(response_score.grade).to eq('Conditional Import')
        end
      end

      context 'documentation-based scoring' do
        it 'evaluates complete documentation package' do
          response_score.update!(
            score_earned: 88.0,
            max_possible_score: 100.0,
            scoring_details: {
              matched_criteria: [
                'product_specifications_complete',
                'certificates_valid',
                'supplier_documentation_complete',
                'shipping_documents_ready'
              ],
              rule_type: 'documentation_assessment',
              criteria_applied: {
                specifications_completeness: 90,
                certificates_validity: 85,
                supplier_docs_completeness: 90,
                shipping_docs_readiness: 85
              },
              calculation_steps: [
                'Verified product specifications: 90%',
                'Validated certificates: 85%',
                'Checked supplier documentation: 90%',
                'Reviewed shipping documents: 85%',
                'Overall documentation score: 88%'
              ]
            }
          )

          expect(response_score.percentage_score).to eq(88.0)
          expect(response_score.grade).to eq('Import Ready')
          expect(response_score.calculation_steps).to include('Overall documentation score: 88%')
        end
      end
    end

    describe 'weighted scoring scenarios' do
      it 'handles weighted criteria correctly' do
        # Set up grade boundaries for this test
        marking_scheme.update!(
          grade_boundaries: {
            'Import Ready' => 50,
            'Not Import Ready' => 0
          }
        )

        response_score.update!(
          score_earned: 77.5,
          max_possible_score: 100.0,
          scoring_details: {
            rule_type: 'weighted_assessment',
            criteria_applied: {
              quality: { score: 85, weight: 0.4 },      # 34 points
              compliance: { score: 70, weight: 0.35 },  # 24.5 points
              documentation: { score: 80, weight: 0.25 } # 20 points
            },
            calculation_steps: [
              'Quality score: 85 × 0.4 = 34.0',
              'Compliance score: 70 × 0.35 = 24.5',
              'Documentation score: 80 × 0.25 = 20.0',
              'Total weighted score: 34.0 + 24.5 + 20.0 = 78.5'
            ]
          }
        )

        expect(response_score.percentage_score).to eq(77.5)
        expect(response_score.grade).to eq('Import Ready')
      end
    end

    describe 'threshold-based dynamic grading' do
      before do
        marking_scheme.update!(
          grade_boundaries: {
            'Excellent Import Ready' => 90,
            'Good Import Ready' => 75,
            'Basic Import Ready' => 50,
            'Needs Review' => 30,
            'Not Import Ready' => 0
          }
        )
      end

      it 'applies correct thresholds for different score ranges' do
        test_scenarios = [
          { score: 95, expected_grade: 'Excellent Import Ready', import_ready: true },
          { score: 82, expected_grade: 'Good Import Ready', import_ready: true },
          { score: 65, expected_grade: 'Basic Import Ready', import_ready: true },
          { score: 45, expected_grade: 'Needs Review', import_ready: false },
          { score: 20, expected_grade: 'Not Import Ready', import_ready: false }
        ]

        test_scenarios.each do |scenario|
          response_score.update!(score_earned: scenario[:score], max_possible_score: 100.0)

          expect(response_score.grade).to eq(scenario[:expected_grade])

          # Import readiness is determined by >= 50% threshold
          expected_pass = scenario[:score] >= 50
          expect(response_score.passed?).to eq(expected_pass)
        end
      end
    end
  end

  describe 'edge cases and error handling' do
    it 'handles zero max possible score gracefully' do
      response_score.update!(score_earned: 0.0, max_possible_score: 0.0)

      expect(response_score.percentage_score).to eq(0.0)
      expect(response_score.passed?).to be false
    end

    it 'handles score earned greater than max possible score' do
      # This could happen due to bonus points or calculation errors
      response_score.update!(score_earned: 110.0, max_possible_score: 100.0)

      expect(response_score.percentage_score).to eq(110.0)
      expect(response_score.passed?).to be true
    end

    it 'handles very large numbers' do
      response_score.update!(score_earned: 999999.99, max_possible_score: 1000000.0)

      expect(response_score.percentage_score).to eq(100.0)
    end

    it 'handles very small decimal differences' do
      response_score.update!(score_earned: 49.999, max_possible_score: 100.0)

      expect(response_score.percentage_score).to eq(50.0) # Rounded up
    end
  end
end
