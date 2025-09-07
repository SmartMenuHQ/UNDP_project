require 'rails_helper'

RSpec.describe 'Simple Conditional Test', type: :model do
  let(:assessment) { create(:assessment) }
  let(:section1) { create(:assessment_section, assessment: assessment, order: 1) }
  let(:trigger_question) { create(:assessment_question, assessment_section: section1, order: 1, is_required: false) }

  describe 'basic conditional setup' do
    it 'creates assessment with sections and questions' do
      expect(assessment).to be_persisted
      expect(section1).to be_persisted
      expect(trigger_question).to be_persisted
      expect(trigger_question.assessment_section).to eq(section1)
    end

    it 'can create conditional section' do
      conditional_section = create(:assessment_section,
        assessment: assessment,
        order: 2,
        is_conditional: true,
        visibility_conditions: {
          trigger_question_id: trigger_question.id,
          trigger_response_type: 'value_equals',
          trigger_values: ['yes'],
          operator: 'equals'
        }
      )

      expect(conditional_section).to be_persisted
      expect(conditional_section.is_conditional?).to be true
      expect(conditional_section.trigger_question_id).to eq(trigger_question.id)
    end

    it 'can create assessment question response' do
      user = create(:user)
      session = create(:assessment_response_session, assessment: assessment, user: user)

      response = create(:assessment_question_response,
        assessment_response_session: session,
        assessment_question: trigger_question,
        assessment: assessment,
        value: { text: 'yes' }
      )

      expect(response).to be_persisted
      expect(response.value).to eq({ 'text' => 'yes' })
    end

    it 'can create marking scheme and rules' do
      marking_scheme = create(:assessment_marking_scheme, assessment: assessment, is_active: true)
      marking_rule = create(:assessment_question_marking_rule,
        assessment_marking_scheme: marking_scheme,
        assessment_question: trigger_question,
        rule_type: 'exact_match',
        points: 10.0
      )

      expect(marking_scheme).to be_persisted
      expect(marking_rule).to be_persisted
      expect(marking_rule.assessment_question).to eq(trigger_question)
    end
  end
end
