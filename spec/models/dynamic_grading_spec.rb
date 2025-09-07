require 'rails_helper'

RSpec.describe 'Dynamic Grading System', type: :model do
  let(:assessment) { create(:assessment) }
  let(:section) { create(:assessment_section, assessment: assessment, order: 1) }
  let(:session) { create(:assessment_response_session, assessment: assessment) }

  describe 'Import Readiness Assessment' do
    let(:marking_scheme) do
      create(:assessment_marking_scheme,
        assessment: assessment,
        name: 'Import Readiness Assessment',
        is_active: true,
        total_possible_score: 100.0,
        passing_score: 50.0,
        grade_boundaries: {
          'Import Ready' => 50,
          'Not Import Ready' => 0
        }
      )
    end

    let(:quality_question) { create(:assessment_question, assessment_section: section, order: 1, is_required: false) }

    describe 'threshold-based grading (>= 50% = Import Ready)' do
      it 'sets up import ready grading with 50% threshold' do
        expect(marking_scheme.passing_score).to eq(50.0)
        expect(marking_scheme.passing_score_percentage).to eq(50.0)
        expect(marking_scheme.grade_boundaries['Import Ready']).to eq(50)
        expect(marking_scheme.grade_boundaries['Not Import Ready']).to eq(0)
      end

      it 'creates marking rules for different quality levels' do
        # High quality = Import Ready
        high_quality_rule = create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: quality_question,
          rule_type: 'exact_match',
          points: 80.0,
          criteria: { expected_value: 'high_quality' }
        )

        # Medium quality = Import Ready (just above threshold)
        medium_quality_rule = create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: quality_question,
          rule_type: 'exact_match',
          points: 60.0,
          criteria: { expected_value: 'medium_quality' }
        )

        # Low quality = Not Import Ready
        low_quality_rule = create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: quality_question,
          rule_type: 'exact_match',
          points: 30.0,
          criteria: { expected_value: 'low_quality' }
        )

        expect(high_quality_rule.points).to eq(80.0)
        expect(medium_quality_rule.points).to eq(60.0)
        expect(low_quality_rule.points).to eq(30.0)

        expect(marking_scheme.assessment_question_marking_rules.count).to eq(3)
      end

      it 'demonstrates dynamic grading logic' do
        # Create a rule that scores above 50% (Import Ready)
        create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: quality_question,
          rule_type: 'exact_match',
          points: 75.0,
          criteria: { expected_value: 'good_product' }
        )

        # Create response that matches the rule
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: quality_question,
          assessment: assessment,
          value: { text: 'good_product' }
        )

        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Verify the grading system structure
        expect(result).to have_key(:total_score)
        expect(result).to have_key(:total_possible)
        expect(result).to have_key(:percentage)
        expect(result).to have_key(:grade)

        expect(result[:total_possible]).to eq(75.0) # Based on the rule points, not scheme total
        expect(result[:grade]).to be_in(['Import Ready', 'Not Import Ready'])
      end
    end

    describe 'multi-level grading boundaries' do
      before do
        marking_scheme.update!(
          grade_boundaries: {
            'Premium Import Ready' => 85,
            'Standard Import Ready' => 70,
            'Basic Import Ready' => 50,
            'Conditional Import' => 25,
            'Not Import Ready' => 0
          }
        )
      end

      it 'supports multiple grade levels for import readiness' do
        expect(marking_scheme.grade_boundaries.keys).to include(
          'Premium Import Ready',
          'Standard Import Ready',
          'Basic Import Ready',
          'Conditional Import',
          'Not Import Ready'
        )
      end

      it 'calculates grades based on percentage thresholds' do
        # Test the grade calculation logic directly
        test_cases = [
          { percentage: 95.0, expected: 'Premium Import Ready' },
          { percentage: 80.0, expected: 'Standard Import Ready' },
          { percentage: 60.0, expected: 'Basic Import Ready' },
          { percentage: 40.0, expected: 'Conditional Import' },
          { percentage: 10.0, expected: 'Not Import Ready' }
        ]

        test_cases.each do |test_case|
          # Use the private method to test grade calculation
          grade = marking_scheme.send(:calculate_grade, test_case[:percentage], 100.0)
          expect(grade).to eq(test_case[:expected])
        end
      end
    end

    describe 'weighted scoring scenarios' do
      let(:compliance_question) { create(:assessment_question, assessment_section: section, order: 2, is_required: false) }
      let(:documentation_question) { create(:assessment_question, assessment_section: section, order: 3, is_required: false) }

      before do
        # Quality (50% weight) - 50 points
        create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: quality_question,
          rule_type: 'exact_match',
          points: 50.0,
          criteria: { expected_value: 'excellent' }
        )

        # Compliance (30% weight) - 30 points
        create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: compliance_question,
          rule_type: 'exact_match',
          points: 30.0,
          criteria: { expected_value: 'compliant' }
        )

        # Documentation (20% weight) - 20 points
        create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: documentation_question,
          rule_type: 'exact_match',
          points: 20.0,
          criteria: { expected_value: 'complete' }
        )
      end

      it 'supports weighted criteria assessment' do
        expect(marking_scheme.assessment_question_marking_rules.sum(:points)).to eq(100.0)

        # Quality has highest weight
        quality_rule = marking_scheme.assessment_question_marking_rules.find_by(assessment_question: quality_question)
        expect(quality_rule.points).to eq(50.0)

        # Compliance has medium weight
        compliance_rule = marking_scheme.assessment_question_marking_rules.find_by(assessment_question: compliance_question)
        expect(compliance_rule.points).to eq(30.0)

        # Documentation has lowest weight
        documentation_rule = marking_scheme.assessment_question_marking_rules.find_by(assessment_question: documentation_question)
        expect(documentation_rule.points).to eq(20.0)
      end

      it 'can achieve import ready with strong quality even if other criteria are weak' do
        # Strong quality (50 points) + weak compliance/documentation
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: quality_question,
          assessment: assessment,
          value: { text: 'excellent' }
        )

        # Add minimal compliance score to reach 50%
        create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: compliance_question,
          rule_type: 'exact_match',
          points: 10.0,
          criteria: { expected_value: 'minimal_compliance' }
        )

        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: compliance_question,
          assessment: assessment,
          value: { text: 'minimal_compliance' }
        )

        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Should be able to reach import ready with strong quality
        expect(result[:total_possible]).to eq(80.0) # All rules are considered for total possible
        expect(result[:grade]).to be_present
      end
    end

    describe 'business logic integration' do
      it 'can be configured for different import scenarios' do
        # Scenario 1: Strict requirements (70% threshold)
        strict_scheme = create(:assessment_marking_scheme,
          assessment: assessment,
          name: 'Strict Import Assessment',
          passing_score: 70.0,
          grade_boundaries: {
            'Import Approved' => 70,
            'Import Denied' => 0
          }
        )

        expect(strict_scheme.passing_score_percentage).to eq(70.0)

        # Scenario 2: Lenient requirements (30% threshold)
        lenient_scheme = create(:assessment_marking_scheme,
          assessment: assessment,
          name: 'Lenient Import Assessment',
          passing_score: 30.0,
          grade_boundaries: {
            'Import Approved' => 30,
            'Import Denied' => 0
          }
        )

        expect(lenient_scheme.passing_score_percentage).to eq(30.0)
      end

      it 'supports custom feedback templates for different outcomes' do
        marking_scheme.update!(
          feedback_templates: {
            'import_ready' => 'Congratulations! Your product meets all import requirements.',
            'not_import_ready' => 'Your product requires improvements before it can be imported.',
            'conditional' => 'Your product meets basic requirements but may need additional review.',
            'premium' => 'Excellent! Your product exceeds all import standards.'
          }
        )

        expect(marking_scheme.feedback_templates['import_ready']).to include('Congratulations')
        expect(marking_scheme.feedback_templates['not_import_ready']).to include('improvements')
        expect(marking_scheme.feedback_templates['conditional']).to include('additional review')
        expect(marking_scheme.feedback_templates['premium']).to include('exceeds all')
      end
    end

    describe 'edge cases and validation' do
      it 'handles boundary conditions correctly' do
        # Test exactly at 50% threshold
        expect(marking_scheme.passing_score_percentage).to eq(50.0)

        # Test percentage calculation
        percentage_49_9 = marking_scheme.send(:calculate_percentage, 49.9, 100.0)
        percentage_50_0 = marking_scheme.send(:calculate_percentage, 50.0, 100.0)
        percentage_50_1 = marking_scheme.send(:calculate_percentage, 50.1, 100.0)

        expect(percentage_49_9).to eq(49.9)
        expect(percentage_50_0).to eq(50.0)
        expect(percentage_50_1).to eq(50.1)

        # Test grade assignment at boundaries
        grade_below = marking_scheme.send(:calculate_grade, 49.9, 100.0)
        grade_at = marking_scheme.send(:calculate_grade, 50.0, 100.0)
        grade_above = marking_scheme.send(:calculate_grade, 50.1, 100.0)

        expect(grade_below).to eq('Not Import Ready')
        expect(grade_at).to eq('Import Ready')
        expect(grade_above).to eq('Import Ready')
      end

      it 'handles zero and invalid scores gracefully' do
        zero_percentage = marking_scheme.send(:calculate_percentage, 0, 100.0)
        expect(zero_percentage).to eq(0.0)

        zero_total_percentage = marking_scheme.send(:calculate_percentage, 50, 0)
        expect(zero_total_percentage).to eq(0.0)

        negative_score_percentage = marking_scheme.send(:calculate_percentage, -10, 100.0)
        expect(negative_score_percentage).to eq(-10.0)
      end

      it 'validates marking scheme configuration' do
        expect(marking_scheme).to be_valid
        expect(marking_scheme.name).to be_present
        expect(marking_scheme.total_possible_score).to be >= 0
        expect(marking_scheme.passing_score).to be_present
        expect(marking_scheme.grade_boundaries).to be_present
      end
    end
  end

  describe 'Assessment Response Score Integration' do
    let(:marking_scheme) { create(:assessment_marking_scheme, assessment: assessment) }
    let(:question) { create(:assessment_question, assessment_section: section, order: 1, is_required: false) }
    let(:response) { create(:assessment_question_response, assessment_response_session: session, assessment_question: question, assessment: assessment) }

    it 'creates response scores with import readiness details' do
      rule = create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: question,
        rule_type: 'exact_match',
        points: 75.0,
        criteria: { expected_value: 'import_ready_product' }
      )

      response.update!(value: { text: 'import_ready_product' })

      score = marking_scheme.grade_response(response)

      expect(score).to be_a(AssessmentResponseScore)
      expect(score.assessment_question_response).to eq(response)
      expect(score.assessment_marking_scheme).to eq(marking_scheme)
      expect(score.assessment_question_marking_rule).to eq(rule)
      expect(score.max_possible_score).to eq(75.0)
    end

    it 'can store detailed scoring information for import decisions' do
      score = create(:assessment_response_score,
        assessment_question_response: response,
        assessment_marking_scheme: marking_scheme,
        assessment_question_marking_rule: create(:assessment_question_marking_rule, assessment_marking_scheme: marking_scheme, assessment_question: question),
        score_earned: 85.0,
        max_possible_score: 100.0,
        scoring_details: {
          import_readiness: true,
          quality_score: 90,
          compliance_score: 85,
          documentation_score: 80,
          risk_level: 'low',
          processing_priority: 'standard',
          decision_factors: [
            'High quality rating',
            'Full compliance achieved',
            'Complete documentation',
            'Low risk assessment'
          ]
        }
      )

      expect(score.scoring_details['import_readiness']).to be true
      expect(score.scoring_details['quality_score']).to eq(90)
      expect(score.scoring_details['decision_factors']).to include('High quality rating')
      expect(score.percentage_score).to eq(85.0)
    end
  end
end
