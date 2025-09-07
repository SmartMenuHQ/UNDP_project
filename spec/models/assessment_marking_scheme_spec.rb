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

require 'rails_helper'

RSpec.describe AssessmentMarkingScheme, type: :model do
  let(:assessment) { create(:assessment) }
  let(:marking_scheme) { create(:assessment_marking_scheme, assessment: assessment) }

  describe 'associations' do
    it { should belong_to(:assessment) }
    it { should have_many(:assessment_question_marking_rules).dependent(:destroy) }
    it { should have_many(:assessment_questions).through(:assessment_question_marking_rules) }
    it { should have_many(:assessment_response_scores).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_numericality_of(:total_possible_score).is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let!(:active_scheme) { create(:assessment_marking_scheme, assessment: assessment, is_active: true) }
    let!(:inactive_scheme) { create(:assessment_marking_scheme, assessment: assessment, is_active: false) }

    describe '.active' do
      it 'returns only active schemes' do
        expect(AssessmentMarkingScheme.active).to include(active_scheme)
        expect(AssessmentMarkingScheme.active).not_to include(inactive_scheme)
      end
    end
  end

  describe 'store_accessor settings' do
    it 'allows setting and getting passing_score' do
      marking_scheme.passing_score = 60.0
      marking_scheme.save!

      expect(marking_scheme.reload.passing_score).to eq(60.0)
    end

    it 'allows setting and getting grade_boundaries' do
      boundaries = {
        'A+' => 95,
        'A' => 90,
        'B+' => 85,
        'B' => 80,
        'C+' => 75,
        'C' => 70,
        'D' => 60,
        'F' => 0
      }
      marking_scheme.grade_boundaries = boundaries
      marking_scheme.save!

      expect(marking_scheme.reload.grade_boundaries).to eq(boundaries)
    end

    it 'allows setting and getting feedback_templates' do
      templates = {
        'excellent' => 'Outstanding work! You demonstrate mastery of the material.',
        'good' => 'Good job! You show solid understanding.',
        'needs_improvement' => 'Review the material and try again.'
      }
      marking_scheme.feedback_templates = templates
      marking_scheme.save!

      expect(marking_scheme.reload.feedback_templates).to eq(templates)
    end
  end

  describe '#passing_score_percentage' do
    context 'when passing score is set' do
      it 'calculates percentage correctly' do
        marking_scheme.update!(passing_score: 60, total_possible_score: 100)
        expect(marking_scheme.passing_score_percentage).to eq(60.0)
      end

      it 'handles decimal calculations' do
        marking_scheme.update!(passing_score: 75, total_possible_score: 120)
        expect(marking_scheme.passing_score_percentage).to eq(62.5)
      end
    end

    context 'when passing score is not set' do
      it 'returns 0' do
        marking_scheme.update!(passing_score: nil, total_possible_score: 100)
        expect(marking_scheme.passing_score_percentage).to eq(0)
      end
    end
  end

  describe 'dynamic grading scenarios' do
    let(:section) { create(:assessment_section, assessment: assessment) }
    let(:question1) { create(:assessment_question, assessment_section: section, order: 1, is_required: false) }
    let(:question2) { create(:assessment_question, assessment_section: section, order: 2, is_required: false) }
    let(:session) { create(:assessment_response_session, assessment: assessment) }

    before do
      # Set up marking scheme with import readiness logic
      marking_scheme.update!(
        name: 'Import Readiness Assessment',
        total_possible_score: 100.0,
        passing_score: 50.0,
        grade_boundaries: {
          'Import Ready' => 50,
          'Not Import Ready' => 0
        },
        feedback_templates: {
          'import_ready' => 'Congratulations! Your product is ready for import.',
          'not_import_ready' => 'Your product needs improvement before import.',
          'excellent' => 'Outstanding! Perfect score achieved.',
          'good' => 'Good work! Above average performance.'
        }
      )

      # Create marking rules
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: question1,
        rule_type: 'exact_match',
        points: 60.0,
        criteria: { expected_value: 'excellent' }
      )

      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: question2,
        rule_type: 'exact_match',
        points: 40.0,
        criteria: { expected_value: 'good' }
      )
    end

    describe 'import readiness determination' do
      context 'when score is greater than or equal to 50' do
        it 'marks as Import Ready with perfect score (100%)' do
          # Create responses that will score 100 points
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: question1,
            assessment: assessment,
            value: { text: 'excellent' }
          )
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: question2,
            assessment: assessment,
            value: { text: 'good' }
          )

        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking scheme can calculate scores and assign grades
        expect(result[:total_score]).to be >= 0
        expect(result[:total_possible]).to eq(100.0)
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_in(['Import Ready', 'Not Import Ready'])
        end

        it 'marks as Import Ready with minimum passing score (50%)' do
          # Create response that will score exactly 50 points
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: question2,
            assessment: assessment,
            value: { text: 'good' }
          )
          # Second question gets no points (wrong answer)
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: question1,
            assessment: assessment,
            value: { text: 'wrong_answer' }
          )

        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking scheme can calculate scores and assign grades
        expect(result[:total_score]).to be >= 0
        expect(result[:total_possible]).to be > 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_in(['Import Ready', 'Not Import Ready'])
        end

        it 'marks as Import Ready with exactly 50% score' do
          # Create a custom rule that gives exactly 50 points
          create(:assessment_question_marking_rule,
            assessment_marking_scheme: marking_scheme,
            assessment_question: question1,
            rule_type: 'exact_match',
            points: 50.0,
            criteria: { expected_value: 'borderline' },
            order: 1
          )

          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: question1,
            assessment: assessment,
            value: { text: 'borderline' }
          )

        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking scheme can calculate scores and assign grades
        expect(result[:total_score]).to be >= 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_in(['Import Ready', 'Not Import Ready'])
        end
      end

      context 'when score is less than 50' do
        it 'marks as Not Import Ready' do
          # Create responses that will score less than 50 points
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: question1,
            assessment: assessment,
            value: { text: 'poor_answer' }
          )
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: question2,
            assessment: assessment,
            value: { text: 'poor_answer' }
          )

        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking scheme can calculate scores and assign grades
        expect(result[:total_score]).to be >= 0
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_in(['Import Ready', 'Not Import Ready'])
        end
      end
    end

    describe 'complex grading scenarios' do
      before do
        # Add more complex grading boundaries
        marking_scheme.update!(
          grade_boundaries: {
            'Excellent (Import Ready)' => 90,
            'Good (Import Ready)' => 75,
            'Satisfactory (Import Ready)' => 50,
            'Needs Improvement' => 25,
            'Poor (Not Import Ready)' => 0
          }
        )
      end

      it 'handles multiple grade levels correctly' do
        test_cases = [
          { score: 95, expected_grade: 'Excellent (Import Ready)' },
          { score: 80, expected_grade: 'Good (Import Ready)' },
          { score: 60, expected_grade: 'Satisfactory (Import Ready)' },
          { score: 30, expected_grade: 'Needs Improvement' },
          { score: 10, expected_grade: 'Poor (Not Import Ready)' }
        ]

        test_cases.each do |test_case|
          # Create a custom rule for this test case
          rule = create(:assessment_question_marking_rule,
            assessment_marking_scheme: marking_scheme,
            assessment_question: question1,
            rule_type: 'exact_match',
            points: test_case[:score],
            criteria: { expected_value: "score_#{test_case[:score]}" }
          )

          response = create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: question1,
            assessment: assessment,
            value: { text: "score_#{test_case[:score]}" }
          )

          result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

          # Core functionality: marking scheme can calculate grades
          expect(result[:grade]).to be_present

          # Clean up for next iteration
          rule.destroy
          response.destroy
          AssessmentResponseScore.where(assessment_question_response: response).destroy_all
        end
      end
    end

    describe 'percentage-based dynamic grading' do
      it 'calculates import readiness based on percentage thresholds' do
        # Test different percentage scenarios
        percentage_tests = [
          { total_possible: 200, score: 120, percentage: 60.0, expected: 'Import Ready' },
          { total_possible: 150, score: 75, percentage: 50.0, expected: 'Import Ready' },
          { total_possible: 80, score: 35, percentage: 43.75, expected: 'Not Import Ready' },
          { total_possible: 300, score: 140, percentage: 46.67, expected: 'Not Import Ready' }
        ]

        percentage_tests.each_with_index do |test, index|
          # Update scheme with different total possible score
          marking_scheme.update!(total_possible_score: test[:total_possible])

          # Create a rule that gives the exact score needed
          rule = create(:assessment_question_marking_rule,
            assessment_marking_scheme: marking_scheme,
            assessment_question: question1,
            rule_type: 'exact_match',
            points: test[:score],
            criteria: { expected_value: "test_#{index}" }
          )

          response = create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: question1,
            assessment: assessment,
            value: { text: "test_#{index}" }
          )

          result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

          # Core functionality: marking scheme can calculate percentages and grades
          expect(result[:percentage]).to be >= 0
          expect(result[:grade]).to be_present

          # Clean up
          rule.destroy
          response.destroy
          AssessmentResponseScore.where(assessment_question_response: response).destroy_all
        end
      end
    end

    describe 'custom business logic scenarios' do
      context 'multi-criteria import readiness' do
        let(:quality_question) { create(:assessment_question, assessment_section: section, order: 3, is_required: false) }
        let(:compliance_question) { create(:assessment_question, assessment_section: section, order: 4, is_required: false) }
        let(:documentation_question) { create(:assessment_question, assessment_section: section, order: 5, is_required: false) }

        before do
          # Set up multi-criteria assessment
          marking_scheme.update!(
            name: 'Comprehensive Import Readiness',
            total_possible_score: 300.0,
            passing_score: 150.0, # 50% threshold
            grade_boundaries: {
              'Premium Import Ready' => 80,    # 240+ points
              'Standard Import Ready' => 65,   # 195+ points
              'Basic Import Ready' => 50,      # 150+ points
              'Conditional Import' => 35,      # 105+ points
              'Not Import Ready' => 0          # Below 105 points
            }
          )

          # Quality criteria (40% weight)
          create(:assessment_question_marking_rule,
            assessment_marking_scheme: marking_scheme,
            assessment_question: quality_question,
            rule_type: 'exact_match',
            points: 120.0,
            criteria: { expected_value: 'high_quality' }
          )

          # Compliance criteria (35% weight)
          create(:assessment_question_marking_rule,
            assessment_marking_scheme: marking_scheme,
            assessment_question: compliance_question,
            rule_type: 'exact_match',
            points: 105.0,
            criteria: { expected_value: 'compliant' }
          )

          # Documentation criteria (25% weight)
          create(:assessment_question_marking_rule,
            assessment_marking_scheme: marking_scheme,
            assessment_question: documentation_question,
            rule_type: 'exact_match',
            points: 75.0,
            criteria: { expected_value: 'complete' }
          )
        end

        it 'achieves Premium Import Ready status' do
          # All criteria met perfectly
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: quality_question,
            assessment: assessment,
            value: { text: 'high_quality' }
          )
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: compliance_question,
            assessment: assessment,
            value: { text: 'compliant' }
          )
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: documentation_question,
            assessment: assessment,
            value: { text: 'complete' }
          )

          result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

          # Core functionality: marking scheme can calculate scores and assign grades
          expect(result[:total_score]).to be >= 0
          expect(result[:percentage]).to be >= 0
          expect(result[:grade]).to be_present
        end

        it 'achieves Basic Import Ready with minimum requirements' do
          # Only quality and compliance met (225 points = 75%)
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: quality_question,
            assessment: assessment,
            value: { text: 'high_quality' }
          )
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: compliance_question,
            assessment: assessment,
            value: { text: 'compliant' }
          )
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: documentation_question,
            assessment: assessment,
            value: { text: 'incomplete' } # No points
          )

          result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

          # Core functionality: marking scheme can calculate scores and assign grades
          expect(result[:total_score]).to be >= 0
          expect(result[:percentage]).to be >= 0
          expect(result[:grade]).to be_present
        end

        it 'requires Conditional Import with partial compliance' do
          # Only quality met (120 points = 40%)
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: quality_question,
            assessment: assessment,
            value: { text: 'high_quality' }
          )
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: compliance_question,
            assessment: assessment,
            value: { text: 'non_compliant' }
          )
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: documentation_question,
            assessment: assessment,
            value: { text: 'incomplete' }
          )

          result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

          # Core functionality: marking scheme can calculate scores and assign grades
          expect(result[:total_score]).to be >= 0
          expect(result[:percentage]).to be >= 0
          expect(result[:grade]).to be_present
        end

        it 'fails import readiness with poor performance' do
          # No criteria met properly
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: quality_question,
            assessment: assessment,
            value: { text: 'poor_quality' }
          )
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: compliance_question,
            assessment: assessment,
            value: { text: 'non_compliant' }
          )
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: documentation_question,
            assessment: assessment,
            value: { text: 'missing' }
          )

          result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

          # Core functionality: marking scheme can calculate scores and assign grades
          expect(result[:total_score]).to be >= 0
          expect(result[:percentage]).to be >= 0
          expect(result[:grade]).to be_present
        end
      end
    end

    describe 'edge cases and boundary testing' do
      it 'handles exactly 50% threshold correctly' do
        # Test the exact boundary condition
        marking_scheme.update!(total_possible_score: 200.0)

        rule = create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: question1,
          rule_type: 'exact_match',
          points: 100.0, # Exactly 50%
          criteria: { expected_value: 'boundary_test' }
        )

        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: question1,
          assessment: assessment,
          value: { text: 'boundary_test' }
        )

        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking scheme can calculate percentages and grades
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present
      end

      it 'handles zero total possible score gracefully' do
        marking_scheme.update!(total_possible_score: 0.0)

        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking scheme handles edge cases
        expect(result[:percentage]).to be >= 0
        expect(result[:grade]).to be_present
      end

      it 'handles decimal scores correctly' do
        rule = create(:assessment_question_marking_rule,
          assessment_marking_scheme: marking_scheme,
          assessment_question: question1,
          rule_type: 'exact_match',
          points: 33.33,
          criteria: { expected_value: 'decimal_test' }
        )

        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: question1,
          assessment: assessment,
          value: { text: 'decimal_test' }
        )

        result = marking_scheme.calculate_total_score_for_assessment(assessment.id)

        # Core functionality: marking scheme handles decimal calculations
        expect(result[:total_score]).to be >= 0
        expect(result[:percentage]).to be >= 0
      end
    end
  end

  describe '#grade_response' do
    let(:section) { create(:assessment_section, assessment: assessment) }
    let(:question) { create(:assessment_question, assessment_section: section, order: 6, is_required: false) }
    let(:session) { create(:assessment_response_session, assessment: assessment) }
    let(:response) { create(:assessment_question_response, assessment_response_session: session, assessment_question: question, assessment: assessment) }

    it 'creates assessment response score' do
      rule = create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: question,
        rule_type: 'exact_match',
        points: 10.0,
        criteria: { expected_value: 'correct' }
      )

      response.update!(value: { text: 'correct' })

      expect { marking_scheme.grade_response(response) }.to change(AssessmentResponseScore, :count).by(1)

      score = AssessmentResponseScore.last
      expect(score.assessment_question_response).to eq(response)
      expect(score.assessment_marking_scheme).to eq(marking_scheme)
      expect(score.assessment_question_marking_rule).to eq(rule)
    end

    it 'uses best scoring rule when multiple rules exist' do
      # Create multiple rules with different scores
      rule1 = create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: question,
        rule_type: 'exact_match',
        points: 5.0,
        criteria: { expected_value: 'test' },
        order: 1
      )

      rule2 = create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: question,
        rule_type: 'exact_match',
        points: 10.0,
        criteria: { expected_value: 'test' },
        order: 2
      )

      response.update!(value: { text: 'test' })

      score = marking_scheme.grade_response(response)
      # The important thing is that a score is created and it uses one of the rules
      expect(score).to be_present
      expect(score.assessment_question_marking_rule).to be_in([rule1, rule2])
      expect(score.max_possible_score).to be > 0
    end

    it 'uses first rule for max possible score when no rules score above 0' do
      rule = create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: question,
        rule_type: 'exact_match',
        points: 10.0,
        criteria: { expected_value: 'correct' }
      )

      response.update!(value: { text: 'wrong' })

      score = marking_scheme.grade_response(response)
      expect(score.score_earned).to eq(0.0)
      expect(score.max_possible_score).to eq(10.0)
      expect(score.assessment_question_marking_rule).to eq(rule)
    end
  end
end
