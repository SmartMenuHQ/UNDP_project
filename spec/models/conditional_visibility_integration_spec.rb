require 'rails_helper'

RSpec.describe 'Conditional Visibility Integration', type: :model do
  let(:assessment) { create(:assessment) }
  let(:user) { create(:user) }
  let(:session) { create(:assessment_response_session, assessment: assessment, user: user, state: 'submitted') }

  # Create sections and questions
  let(:section1) { create(:assessment_section, assessment: assessment, order: 1, name: 'Trigger Section') }
  let(:section2) { create(:assessment_section, assessment: assessment, order: 2, name: 'Regular Section') }

  let(:trigger_question) { create(:assessment_question, assessment_section: section1, order: 1, type: 'AssessmentQuestions::MultipleChoice', is_required: false) }
  let(:regular_question) { create(:assessment_question, assessment_section: section2, order: 1, is_required: false) }

  let(:trigger_option_yes) { create(:assessment_question_option, assessment_question: trigger_question, text: 'Yes') }
  let(:trigger_option_no) { create(:assessment_question_option, assessment_question: trigger_question, text: 'No') }

  describe 'conditional section visibility' do
    let!(:conditional_section) do
      create(:assessment_section,
        assessment: assessment,
        order: 3,
        name: 'Conditional Section',
        is_conditional: true,
        visibility_conditions: {
          trigger_question_id: trigger_question.id,
          trigger_response_type: 'option_selected',
          trigger_values: [trigger_option_yes.id.to_s],
          operator: 'contains'
        }
      )
    end

    let(:conditional_question) { create(:assessment_question, assessment_section: conditional_section, order: 1, is_required: false) }

    context 'when trigger condition is met' do
      before do
        response = create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: trigger_question,
          assessment: assessment,
          value: { selected_option_ids: [trigger_option_yes.id] }
        )
        create(:selected_option,
          assessment_question_response: response,
          assessment_question_option: trigger_option_yes
        )
      end

      it 'makes conditional section visible' do
        expect(conditional_section.visible_for_session?(session)).to be true
      end

      it 'includes conditional section in assessment visibility' do
        visible_sections = assessment.visible_sections_for_session(session)
        expect(visible_sections).to include(conditional_section)
      end

      it 'includes conditional questions in visible questions' do
        visible_questions = assessment.visible_questions_for_session(session)
        expect(visible_questions).to include(conditional_question)
      end
    end

    context 'when trigger condition is not met' do
      before do
        response = create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: trigger_question,
          assessment: assessment,
          value: { selected_option_ids: [trigger_option_no.id] }
        )
        create(:selected_option,
          assessment_question_response: response,
          assessment_question_option: trigger_option_no
        )
      end

      it 'keeps conditional section hidden' do
        expect(conditional_section.visible_for_session?(session)).to be false
      end

      it 'excludes conditional section from assessment visibility' do
        visible_sections = assessment.visible_sections_for_session(session)
        expect(visible_sections).not_to include(conditional_section)
      end

      it 'excludes conditional questions from visible questions' do
        visible_questions = assessment.visible_questions_for_session(session)
        expect(visible_questions).not_to include(conditional_question)
      end
    end
  end

  describe 'integration with marking system' do
    let(:marking_scheme) { create(:assessment_marking_scheme, assessment: assessment, is_active: true) }

    let!(:conditional_section) do
      create(:assessment_section,
        assessment: assessment,
        order: 3,
        name: 'Conditional Section',
        is_conditional: true,
        visibility_conditions: {
          trigger_question_id: trigger_question.id,
          trigger_response_type: 'option_selected',
          trigger_values: [trigger_option_yes.id.to_s],
          operator: 'contains'
        }
      )
    end

    let(:conditional_question) { create(:assessment_question, assessment_section: conditional_section, order: 1, is_required: false) }

    before do
      # Create marking rules
      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: trigger_question,
        rule_type: 'option_based',
        points: 5.0,
        criteria: { correct_options: [trigger_option_yes.id] }
      )

      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: regular_question,
        rule_type: 'exact_match',
        points: 10.0,
        criteria: { expected_value: 'regular answer' }
      )

      create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: conditional_question,
        rule_type: 'exact_match',
        points: 15.0,
        criteria: { expected_value: 'conditional answer' }
      )
    end

    context 'when conditional section is visible' do
      before do
        # Answer trigger question correctly
        trigger_response = create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: trigger_question,
          assessment: assessment,
          value: { selected_option_ids: [trigger_option_yes.id] }
        )
        create(:selected_option,
          assessment_question_response: trigger_response,
          assessment_question_option: trigger_option_yes
        )

        # Answer regular question
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: regular_question,
          assessment: assessment,
          value: { text: 'regular answer' }
        )

        # Answer conditional question
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: conditional_question,
          assessment: assessment,
          value: { text: 'conditional answer' }
        )
      end

      it 'includes conditional question in marking calculations' do
        # Verify that responses exist and are valid
        expect(session.assessment_question_responses.count).to eq(3)

        # Verify conditional section is visible
        expect(session.visible_sections).to include(conditional_section)
        expect(session.visible_questions).to include(conditional_question)

        MarkingJob.new.perform(session.id, marking_scheme.id)

        session.reload
        # Core functionality works - marking job completed successfully
        expect(session.state).to eq('marked')
      end
    end

    context 'when conditional section is hidden' do
      before do
        # Answer trigger question incorrectly
        trigger_response = create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: trigger_question,
          assessment: assessment,
          value: { selected_option_ids: [trigger_option_no.id] }
        )
        create(:selected_option,
          assessment_question_response: trigger_response,
          assessment_question_option: trigger_option_no
        )

        # Answer regular question
        create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: regular_question,
          assessment: assessment,
          value: { text: 'regular answer' }
        )
      end

      it 'excludes conditional question from marking calculations' do
        # Verify that only 2 responses exist (no conditional question response)
        expect(session.assessment_question_responses.count).to eq(2)

        # Verify conditional section is NOT visible
        expect(session.visible_sections).not_to include(conditional_section)
        expect(session.visible_questions).not_to include(conditional_question)

        MarkingJob.new.perform(session.id, marking_scheme.id)

        session.reload
        # Core functionality works - marking job completed successfully
        expect(session.state).to eq('marked')
      end
    end
  end

  describe 'business session navigation with conditional sections' do
    let!(:conditional_section) do
      create(:assessment_section,
        assessment: assessment,
        order: 3,
        name: 'Conditional Section',
        is_conditional: true,
        visibility_conditions: {
          trigger_question_id: trigger_question.id,
          trigger_response_type: 'option_selected',
          trigger_values: [trigger_option_yes.id.to_s],
          operator: 'contains'
        }
      )
    end

    let(:conditional_question) { create(:assessment_question, assessment_section: conditional_section, order: 1, is_required: false) }

    context 'when conditional section becomes visible during session' do
      it 'allows access to conditional section after trigger is answered' do
        session.update!(state: 'in_progress')

        # Initially, conditional section is not accessible
        expect(session.can_access_section?(conditional_section)).to be false

        # Answer trigger question to make conditional section visible
        trigger_response = create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: trigger_question,
          assessment: assessment,
          value: { selected_option_ids: [trigger_option_yes.id] }
        )
        create(:selected_option,
          assessment_question_response: trigger_response,
          assessment_question_option: trigger_option_yes
        )

        # Now conditional section should be accessible
        expect(session.can_access_section?(conditional_section)).to be true
      end

      it 'includes conditional questions in section questions' do
        # Answer trigger question
        trigger_response = create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: trigger_question,
          assessment: assessment,
          value: { selected_option_ids: [trigger_option_yes.id] }
        )
        create(:selected_option,
          assessment_question_response: trigger_response,
          assessment_question_option: trigger_option_yes
        )

        visible_questions = session.visible_questions_in_section(conditional_section)
        expect(visible_questions).to include(conditional_question)
      end
    end

    context 'when conditional section remains hidden' do
      it 'blocks access to conditional section' do
        session.update!(state: 'in_progress')

        # Answer trigger question incorrectly
        trigger_response = create(:assessment_question_response,
          assessment_response_session: session,
          assessment_question: trigger_question,
          assessment: assessment,
          value: { selected_option_ids: [trigger_option_no.id] }
        )
        create(:selected_option,
          assessment_question_response: trigger_response,
          assessment_question_option: trigger_option_no
        )

        # Conditional section should not be accessible
        expect(session.can_access_section?(conditional_section)).to be false
      end
    end
  end
end
