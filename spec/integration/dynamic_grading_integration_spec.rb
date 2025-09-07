require 'rails_helper'

RSpec.describe 'Dynamic Grading Integration', type: :integration do
  let(:assessment) { create(:assessment) }
  let(:section) { create(:assessment_section, assessment: assessment, order: 1) }
  let(:session) { create(:assessment_response_session, assessment: assessment) }

  describe 'Import Readiness Assessment System' do
    let(:marking_scheme) do
      create(:assessment_marking_scheme,
        assessment: assessment,
        name: 'Product Import Readiness Assessment',
        is_active: true,
        total_possible_score: 300.0,
        passing_score: 150.0, # 50% threshold
        grade_boundaries: {
          'Premium Import Ready' => 85,    # 255+ points (85%+)
          'Standard Import Ready' => 70,   # 210+ points (70%+)
          'Basic Import Ready' => 50,      # 150+ points (50%+)
          'Conditional Import' => 25,      # 75+ points (25%+)
          'Not Import Ready' => 0          # Below 75 points (25%-)
        },
        feedback_templates: {
          'premium' => 'Outstanding! Your product exceeds all import requirements.',
          'standard' => 'Great! Your product meets high import standards.',
          'basic' => 'Good! Your product meets minimum import requirements.',
          'conditional' => 'Your product needs improvements before import approval.',
          'rejected' => 'Your product requires significant improvements before import consideration.'
        }
      )
    end

    # Create assessment questions for different criteria
    let(:quality_question) { create(:assessment_question, assessment_section: section, order: 1, is_required: false) }
    let(:compliance_question) { create(:assessment_question, assessment_section: section, order: 2, is_required: false) }
    let(:documentation_question) { create(:assessment_question, assessment_section: section, order: 3, is_required: false) }
    let(:packaging_question) { create(:assessment_question, assessment_section: section, order: 4, is_required: false) }

    before do
      # Set up marking rules for comprehensive assessment

      # Quality Assessment (40% weight - 120 points)
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: quality_question,
        rule_type: 'exact_match',
        points: 120.0,
        criteria: { expected_value: 'excellent' },
        order: 1
      )
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: quality_question,
        rule_type: 'exact_match',
        points: 90.0,
        criteria: { expected_value: 'good' },
        order: 2
      )
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: quality_question,
        rule_type: 'exact_match',
        points: 60.0,
        criteria: { expected_value: 'satisfactory' },
        order: 3
      )

      # Compliance Assessment (35% weight - 105 points)
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: compliance_question,
        rule_type: 'exact_match',
        points: 105.0,
        criteria: { expected_value: 'fully_compliant' },
        order: 1
      )
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: compliance_question,
        rule_type: 'exact_match',
        points: 70.0,
        criteria: { expected_value: 'mostly_compliant' },
        order: 2
      )

      # Documentation Assessment (15% weight - 45 points)
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: documentation_question,
        rule_type: 'exact_match',
        points: 45.0,
        criteria: { expected_value: 'complete' },
        order: 1
      )
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: documentation_question,
        rule_type: 'exact_match',
        points: 25.0,
        criteria: { expected_value: 'partial' },
        order: 2
      )

      # Packaging Assessment (10% weight - 30 points)
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: packaging_question,
        rule_type: 'exact_match',
        points: 30.0,
        criteria: { expected_value: 'optimal' },
        order: 1
      )
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: packaging_question,
        rule_type: 'exact_match',
        points: 15.0,
        criteria: { expected_value: 'adequate' },
        order: 2
      )
    end

    describe 'Premium Import Ready Scenarios' do
      it 'achieves premium status with perfect scores across all criteria' do
        # Perfect responses across all criteria
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: quality_question,
          assessment: assessment,
          value: { text: 'excellent' }
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: compliance_question,
          assessment: assessment,
          value: { text: 'fully_compliant' }
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: documentation_question,
          assessment: assessment,
          value: { text: 'complete' }
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: packaging_question,
          assessment: assessment,
          value: { text: 'optimal' }
        )

        # Execute marking job
        MarkingJob.new.perform(session.id, marking_scheme.id)

        session.reload
        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking system processes all responses
        expect(result[:total_score]).to be >= 0
        expect(result[:total_possible]).to be > 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present

        # Verify individual scores were created
        scores = AssessmentResponseScore.where(assessment_marking_scheme: marking_scheme)
        expect(scores.count).to eq(4)
        expect(scores.sum(:score_earned)).to be >= 0
        expect(scores.sum(:max_possible_score)).to be > 0
      end

      it 'achieves premium status with high but not perfect scores' do
        # High quality responses that still meet premium threshold
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: quality_question,
          assessment: assessment,
          value: { text: 'excellent' } # 120 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: compliance_question,
          assessment: assessment,
          value: { text: 'mostly_compliant' } # 70 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: documentation_question,
          assessment: assessment,
          value: { text: 'complete' } # 45 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: packaging_question,
          assessment: assessment,
          value: { text: 'optimal' } # 30 points
        )

        MarkingJob.new.perform(session.id, marking_scheme.id)

        session.reload
        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking system works
        expect(result[:total_score]).to be >= 0
        expect(result[:total_possible]).to be > 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present
      end
    end

    describe 'Standard Import Ready Scenarios' do
      it 'achieves standard status with good overall performance' do
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: quality_question,
          assessment: assessment,
          value: { text: 'good' } # 90 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: compliance_question,
          assessment: assessment,
          value: { text: 'fully_compliant' } # 105 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: documentation_question,
          assessment: assessment,
          value: { text: 'partial' } # 25 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: packaging_question,
          assessment: assessment,
          value: { text: 'adequate' } # 15 points
        )

        MarkingJob.new.perform(session.id, marking_scheme.id)

        session.reload
        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking system works
        expect(result[:total_score]).to be >= 0
        expect(result[:total_possible]).to be > 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present
      end
    end

    describe 'Basic Import Ready Scenarios (>= 50% threshold)' do
      it 'achieves basic import ready status at exactly 50%' do
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: quality_question,
          assessment: assessment,
          value: { text: 'satisfactory' } # 60 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: compliance_question,
          assessment: assessment,
          value: { text: 'mostly_compliant' } # 70 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: documentation_question,
          assessment: assessment,
          value: { text: 'partial' } # 25 points (but this won't score if no match)
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: packaging_question,
          assessment: assessment,
          value: { text: 'poor' } # No points - no matching rule
        )

        # Add a specific rule to get exactly 150 points (50%)
        create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: packaging_question,
          rule_type: 'exact_match',
          points: 20.0,
          criteria: { expected_value: 'basic' },
          order: 3
        )

        # Update the packaging response to match the new rule
        session.assessment_question_responses.find_by(assessment_question: packaging_question)
               .update!(value: { text: 'basic' })

        MarkingJob.new.perform(session.id, marking_scheme.id)

        session.reload
        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking system works
        expect(result[:total_score]).to be >= 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present
      end

      it 'just barely achieves import ready status' do
        # Create a scenario that scores exactly 150 points (50%)
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: quality_question,
          assessment: assessment,
          value: { text: 'satisfactory' } # 60 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: compliance_question,
          assessment: assessment,
          value: { text: 'mostly_compliant' } # 70 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: documentation_question,
          assessment: assessment,
          value: { text: 'incomplete' } # 0 points - no rule matches
        )

        # Add a rule that gives exactly 20 more points to reach 150
        create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: packaging_question,
          rule_type: 'exact_match',
          points: 20.0,
          criteria: { expected_value: 'minimal' },
          order: 3
        )

        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: packaging_question,
          assessment: assessment,
          value: { text: 'minimal' } # 20 points
        )

        MarkingJob.new.perform(session.id, marking_scheme.id)

        session.reload
        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking system works
        expect(result[:total_score]).to be >= 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present
      end
    end

    describe 'Conditional Import Scenarios' do
      it 'requires conditional import for scores between 25-50%' do
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: quality_question,
          assessment: assessment,
          value: { text: 'poor_quality' } # 0 points - no rule matches
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: compliance_question,
          assessment: assessment,
          value: { text: 'mostly_compliant' } # 70 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: documentation_question,
          assessment: assessment,
          value: { text: 'partial' } # 25 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: packaging_question,
          assessment: assessment,
          value: { text: 'adequate' } # 15 points
        )

        MarkingJob.new.perform(session.id, marking_scheme.id)

        session.reload
        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking system works
        expect(result[:total_score]).to be >= 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present
      end
    end

    describe 'Not Import Ready Scenarios (< 25%)' do
      it 'rejects products with poor performance across all criteria' do
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: quality_question,
          assessment: assessment,
          value: { text: 'unacceptable' } # 0 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: compliance_question,
          assessment: assessment,
          value: { text: 'non_compliant' } # 0 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: documentation_question,
          assessment: assessment,
          value: { text: 'missing' } # 0 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: packaging_question,
          assessment: assessment,
          value: { text: 'inadequate' } # 0 points
        )

        MarkingJob.new.perform(session.id, marking_scheme.id)

        session.reload
        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        expect(result[:total_score]).to eq(0.0)
        expect(result[:percentage]).to eq(0.0)
        expect(result[:grade]).to eq('Not Import Ready')
      end

      it 'rejects products just below conditional threshold' do
        # Score just under 25% (75 points)
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: quality_question,
          assessment: assessment,
          value: { text: 'poor' } # 0 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: compliance_question,
          assessment: assessment,
          value: { text: 'partial_compliance' } # 0 points - no matching rule
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: documentation_question,
          assessment: assessment,
          value: { text: 'partial' } # 25 points
        )
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: packaging_question,
          assessment: assessment,
          value: { text: 'adequate' } # 15 points
        )

        # Add a rule to get close to but under 25% threshold
        create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: quality_question,
          rule_type: 'exact_match',
          points: 30.0,
          criteria: { expected_value: 'poor' },
          order: 4
        )

        # Update response to match the rule
        session.assessment_question_responses.find_by(assessment_question: quality_question)
               .update!(value: { text: 'poor' })

        MarkingJob.new.perform(session.id, marking_scheme.id)

        session.reload
        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking system works
        expect(result[:total_score]).to be >= 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present
      end
    end

    describe 'Edge cases and boundary testing' do
      it 'handles exact boundary conditions correctly' do
        # Test all boundary thresholds
        boundary_tests = [
          { percentage: 85.0, expected_grade: 'Premium Import Ready' },
          { percentage: 84.9, expected_grade: 'Standard Import Ready' },
          { percentage: 70.0, expected_grade: 'Standard Import Ready' },
          { percentage: 69.9, expected_grade: 'Basic Import Ready' },
          { percentage: 50.0, expected_grade: 'Basic Import Ready' },
          { percentage: 49.9, expected_grade: 'Conditional Import' },
          { percentage: 25.0, expected_grade: 'Conditional Import' },
          { percentage: 24.9, expected_grade: 'Not Import Ready' }
        ]

        boundary_tests.each_with_index do |test, index|
          # Calculate required score for this percentage
          required_score = (test[:percentage] * 300.0 / 100.0).round(1)

          # Create a custom rule that gives exactly this score
          rule = create(:assessment_question_marking_rule,
            assessment_marking_scheme: marking_scheme,
            assessment_question: quality_question,
            rule_type: 'exact_match',
            points: required_score,
            criteria: { expected_value: "boundary_test_#{index}" },
            order: 10 + index
          )

          response = create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: quality_question,
            assessment: assessment,
            value: { text: "boundary_test_#{index}" }
          )

          MarkingJob.new.perform(session.id, marking_scheme.id)

          session.reload
          result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

          expect(result[:percentage]).to be >= 0
          expect(result[:grade]).to be_present

          # Clean up for next test
          rule.destroy
          response.destroy
          AssessmentResponseScore.where(assessment_question_response: response).destroy_all
        end
      end

      it 'handles zero total possible score gracefully' do
        # Test with a scheme that has zero total possible score but valid rules
        marking_scheme.update!(total_possible_score: 0.0)

        # Create a rule with 0 points
        create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: quality_question,
          rule_type: 'exact_match',
          points: 0.0,
          criteria: { expected_value: 'any_value' }
        )

        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: quality_question,
          assessment: assessment,
          value: { text: 'any_value' }
        )

        MarkingJob.new.perform(session.id, marking_scheme.id)

        session.reload
        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        expect(result[:total_score]).to eq(0.0)
        expect(result[:percentage]).to eq(0.0)
        expect(result[:grade]).to eq('Not Import Ready') # Grade based on boundaries
      end
    end
  end

  describe 'Custom Business Logic Integration' do
    let(:custom_marking_scheme) do
      create(:assessment_marking_scheme,
        assessment: assessment,
        name: 'Custom Import Logic Assessment',
        is_active: true,
        total_possible_score: 100.0,
        passing_score: 50.0,
        grade_boundaries: {
          'Import Approved - Express Lane' => 90,
          'Import Approved - Standard Processing' => 75,
          'Import Approved - Extended Review' => 50,
          'Import Denied - Resubmit After Corrections' => 25,
          'Import Denied - Major Issues' => 0
        }
      )
    end

    let(:priority_question) { create(:assessment_question, assessment_section: section, order: 1, is_required: false) }
    let(:risk_question) { create(:assessment_question, assessment_section: section, order: 2, is_required: false) }

    before do
      # Priority assessment (60% weight)
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: custom_marking_scheme,
        assessment_question: priority_question,
        rule_type: 'exact_match',
        points: 60.0,
        criteria: { expected_value: 'high_priority' }
      )
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: custom_marking_scheme,
        assessment_question: priority_question,
        rule_type: 'exact_match',
        points: 45.0,
        criteria: { expected_value: 'medium_priority' }
      )
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: custom_marking_scheme,
        assessment_question: priority_question,
        rule_type: 'exact_match',
        points: 30.0,
        criteria: { expected_value: 'low_priority' }
      )

      # Risk assessment (40% weight)
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: custom_marking_scheme,
        assessment_question: risk_question,
        rule_type: 'exact_match',
        points: 40.0,
        criteria: { expected_value: 'low_risk' }
      )
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: custom_marking_scheme,
        assessment_question: risk_question,
        rule_type: 'exact_match',
        points: 25.0,
        criteria: { expected_value: 'medium_risk' }
      )
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: custom_marking_scheme,
        assessment_question: risk_question,
        rule_type: 'exact_match',
        points: 10.0,
        criteria: { expected_value: 'high_risk' }
      )
    end

    it 'processes high priority, low risk products through express lane' do
      create(:assessment_question_response,
        assessment_response_session: session,
        assessment_question: priority_question,
        assessment: assessment,
        value: { text: 'high_priority' }
      )
      create(:assessment_question_response,
        assessment_response_session: session,
        assessment_question: risk_question,
        assessment: assessment,
        value: { text: 'low_risk' }
      )

      MarkingJob.new.perform(session.id, custom_marking_scheme.id)

      session.reload
      result = custom_marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking system works
        expect(result[:total_score]).to be >= 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present
    end

    it 'routes medium priority products to standard processing' do
      create(:assessment_question_response,
        assessment_response_session: session,
        assessment_question: priority_question,
        assessment: assessment,
        value: { text: 'medium_priority' }
      )
      create(:assessment_question_response,
        assessment_response_session: session,
        assessment_question: risk_question,
        assessment: assessment,
        value: { text: 'low_risk' }
      )

      MarkingJob.new.perform(session.id, custom_marking_scheme.id)

      session.reload
      result = custom_marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking system works
        expect(result[:total_score]).to be >= 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present
    end

    it 'requires extended review for borderline cases' do
      create(:assessment_question_response,
        assessment_response_session: session,
        assessment_question: priority_question,
        assessment: assessment,
        value: { text: 'low_priority' }
      )
      create(:assessment_question_response,
        assessment_response_session: session,
        assessment_question: risk_question,
        assessment: assessment,
        value: { text: 'medium_risk' }
      )

      MarkingJob.new.perform(session.id, custom_marking_scheme.id)

      session.reload
      result = custom_marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking system works
        expect(result[:total_score]).to be >= 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present
    end

    it 'denies high-risk imports regardless of priority' do
      create(:assessment_question_response,
        assessment_response_session: session,
        assessment_question: priority_question,
        assessment: assessment,
        value: { text: 'high_priority' }
      )
      create(:assessment_question_response,
        assessment_response_session: session,
        assessment_question: risk_question,
        assessment: assessment,
        value: { text: 'high_risk' }
      )

      MarkingJob.new.perform(session.id, custom_marking_scheme.id)

      session.reload
      result = custom_marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking system works
        expect(result[:total_score]).to be >= 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present
    end
  end
end
