# == Schema Information
#
# Table name: assessment_sections
#
#  id                       :bigint           not null, primary key
#  has_country_restrictions :boolean          default(FALSE), not null
#  is_conditional           :boolean          default(FALSE)
#  metadata                 :jsonb
#  name                     :string
#  order                    :integer
#  restricted_countries     :jsonb
#  visibility_conditions    :jsonb
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  assessment_id            :bigint           not null
#

require 'rails_helper'

RSpec.describe AssessmentSection, type: :model do
  let(:assessment) { create(:assessment) }
  let(:section) { create(:assessment_section, assessment: assessment) }

  describe 'associations' do
    subject { build(:assessment_section, assessment: assessment, name: 'Test Section', order: 1) }

    it { should belong_to(:assessment) }
    it { should have_many(:assessment_questions).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:assessment_section, assessment: assessment, name: 'Test Section', order: 1) }

    it 'validates presence of name when auto-generation is disabled' do
      section = build(:assessment_section, assessment: assessment, name: '', order: 1)
      allow(section).to receive(:should_auto_generate_name?).and_return(false)
      expect(section).not_to be_valid
      expect(section.errors[:name]).to include("can't be blank")
    end

    it 'validates length of name' do
      section = build(:assessment_section, assessment: assessment, name: 'a' * 256, order: 1)
      expect(section).not_to be_valid
      expect(section.errors[:name]).to include("is too long (maximum is 255 characters)")
    end

    it 'validates presence of order when auto-generation is disabled' do
      section = build(:assessment_section, assessment: assessment, name: 'Test', order: nil)
      allow(section).to receive(:should_auto_set_order?).and_return(false)
      expect(section).not_to be_valid
      expect(section.errors[:order]).to include("can't be blank")
    end

    it 'validates order is greater than 0' do
      section = build(:assessment_section, assessment: assessment, name: 'Test', order: 0)
      expect(section).not_to be_valid
      expect(section.errors[:order]).to include("must be greater than 0")
    end

    it 'validates uniqueness of order within assessment' do
      create(:assessment_section, assessment: assessment, order: 1)
      section = build(:assessment_section, assessment: assessment, order: 1)
      expect(section).not_to be_valid
      expect(section.errors[:order]).to include("has already been taken")
    end
  end

  describe 'includes' do
    it 'includes ConditionalVisibility' do
      expect(AssessmentSection.included_modules).to include(ConditionalVisibility)
    end

    it 'includes CountryRestrictable' do
      expect(AssessmentSection.included_modules).to include(CountryRestrictable)
    end
  end

  describe 'scopes' do
    before do
      # Clear existing sections to avoid order conflicts
      assessment.assessment_sections.destroy_all
    end

    let!(:section1) { create(:assessment_section, assessment: assessment, order: 2, name: 'Section 2') }
    let!(:section2) { create(:assessment_section, assessment: assessment, order: 1, name: 'Section 1') }
    let!(:section3) { create(:assessment_section, assessment: assessment, order: 3, name: 'Section 3') }

    describe '.ordered' do
      it 'returns sections in order' do
        expect(assessment.assessment_sections.ordered).to eq([section2, section1, section3])
      end
    end

    describe '.conditional' do
      let!(:trigger_section) { create(:assessment_section, assessment: assessment, order: 4, name: 'Trigger Section') }
      let!(:trigger_question) { create(:assessment_question, assessment_section: trigger_section, order: 1) }
      let!(:conditional_section) {
        create(:assessment_section,
          assessment: assessment,
          order: 5,
          name: 'Conditional Section',
          is_conditional: true,
          visibility_conditions: {
            trigger_question_id: trigger_question.id,
            trigger_response_type: 'option_selected',
            trigger_values: ['1'],
            operator: 'contains'
          }
        )
      }
      let!(:unconditional_section) { create(:assessment_section, assessment: assessment, order: 6, name: 'Unconditional Section') }

      it 'returns only conditional sections' do
        expect(AssessmentSection.conditional).to include(conditional_section)
        expect(AssessmentSection.conditional).not_to include(unconditional_section)
      end
    end
  end

  describe 'conditional visibility' do
    let(:trigger_question) { create(:assessment_question, assessment_section: section, order: 1) }
    let(:conditional_section) { create(:assessment_section, assessment: assessment, order: 2) }
    let(:user) { create(:user) }
    let(:session) { create(:assessment_response_session, assessment: assessment, user: user) }

    describe 'validation' do
      context 'when is_conditional is true' do
        it 'validates presence of trigger_question_id' do
          conditional_section.update(is_conditional: true, visibility_conditions: {})
          expect(conditional_section).not_to be_valid
          expect(conditional_section.errors[:trigger_question_id]).to include("can't be blank")
        end

        it 'validates presence of trigger_response_type' do
          conditional_section.update(
            is_conditional: true,
            visibility_conditions: { trigger_question_id: trigger_question.id }
          )
          expect(conditional_section).not_to be_valid
          expect(conditional_section.errors[:trigger_response_type]).to include("can't be blank")
        end

        it 'validates presence of trigger_values' do
          conditional_section.update(
            is_conditional: true,
            visibility_conditions: {
              trigger_question_id: trigger_question.id,
              trigger_response_type: 'option_selected'
            }
          )
          expect(conditional_section).not_to be_valid
          expect(conditional_section.errors[:trigger_values]).to include("can't be blank")
        end

        it 'validates trigger question exists' do
          conditional_section.update(
            is_conditional: true,
            visibility_conditions: {
              trigger_question_id: 99999,
              trigger_response_type: 'option_selected',
              trigger_values: ['1']
            }
          )
          expect(conditional_section).not_to be_valid
        end

        it 'validates trigger question precedes current section' do
          later_question = create(:assessment_question,
            assessment_section: create(:assessment_section, assessment: assessment, order: 3),
            order: 1
          )

          conditional_section.update(
            is_conditional: true,
            visibility_conditions: {
              trigger_question_id: later_question.id,
              trigger_response_type: 'option_selected',
              trigger_values: ['1']
            }
          )
          expect(conditional_section).not_to be_valid
        end
      end

      context 'when is_conditional is false' do
        it 'does not validate conditional fields' do
          conditional_section.update(is_conditional: false, visibility_conditions: {})
          expect(conditional_section).to be_valid
        end
      end
    end

    describe '#visible_for_session?' do
      context 'when section is not conditional' do
        it 'returns true' do
          expect(section.visible_for_session?(session)).to be true
        end
      end

      context 'when section is conditional' do
        let(:option1) { create(:assessment_question_option, assessment_question: trigger_question) }
        let(:option2) { create(:assessment_question_option, assessment_question: trigger_question) }

        before do
          conditional_section.update!(
            is_conditional: true,
            trigger_question_id: trigger_question.id,
            trigger_response_type: 'option_selected',
            trigger_values: [option1.id.to_s],
            operator: 'contains'
          )
        end

        context 'when trigger condition is met' do
          before do
            response = create(:assessment_question_response,
              assessment_response_session: session,
              assessment_question: trigger_question,
              assessment: assessment
            )
            create(:selected_option,
              assessment_question_response: response,
              assessment_question_option: option1
            )
          end

          it 'returns true' do
            expect(conditional_section.visible_for_session?(session)).to be true
          end
        end

        context 'when trigger condition is not met' do
          before do
            response = create(:assessment_question_response,
              assessment_response_session: session,
              assessment_question: trigger_question,
              assessment: assessment
            )
            create(:selected_option,
              assessment_question_response: response,
              assessment_question_option: option2
            )
          end

          it 'returns false' do
            expect(conditional_section.visible_for_session?(session)).to be false
          end
        end

        context 'when no response to trigger question' do
          it 'returns false' do
            expect(conditional_section.visible_for_session?(session)).to be false
          end
        end
      end
    end

    describe 'different trigger types' do
      let(:text_question) { create(:assessment_question, assessment_section: section, order: 1, type: 'AssessmentQuestions::RichText') }
      let(:number_question) { create(:assessment_question, assessment_section: section, order: 2, type: 'AssessmentQuestions::RangeType') }

      context 'value_equals trigger' do
        before do
          conditional_section.update!(
            is_conditional: true,
            trigger_question_id: text_question.id,
            trigger_response_type: 'value_equals',
            trigger_values: ['Yes'],
            operator: 'equals'
          )
        end

        it 'shows when text response equals trigger value' do
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: text_question,
            assessment: assessment,
            value: { text: 'Yes' }
          )

          expect(conditional_section.visible_for_session?(session)).to be true
        end

        it 'hides when text response does not equal trigger value' do
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: text_question,
            assessment: assessment,
            value: { text: 'No' }
          )

          expect(conditional_section.visible_for_session?(session)).to be false
        end
      end

      context 'value_range trigger' do
        before do
          conditional_section.update!(
            is_conditional: true,
            trigger_question_id: number_question.id,
            trigger_response_type: 'value_range',
            trigger_values: ['10', '50'],
            operator: 'between'
          )
        end

        it 'shows when numeric response is within range' do
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: number_question,
            assessment: assessment,
            value: { number: 25 }
          )

          expect(conditional_section.visible_for_session?(session)).to be true
        end

        it 'hides when numeric response is outside range' do
          create(:assessment_question_response,
            assessment_response_session: session,
            assessment_question: number_question,
            assessment: assessment,
            value: { number: 75 }
          )

          expect(conditional_section.visible_for_session?(session)).to be false
        end
      end
    end
  end

  describe 'instance methods' do
    let(:test_section) { create(:assessment_section, assessment: assessment, name: 'Test Section', order: 1) }
    let!(:required_questions) {
      [
        create(:assessment_question, assessment_section: test_section, is_required: true, order: 1),
        create(:assessment_question, assessment_section: test_section, is_required: true, order: 2)
      ]
    }
    let!(:optional_questions) {
      [
        create(:assessment_question, assessment_section: test_section, is_required: false, order: 3),
        create(:assessment_question, assessment_section: test_section, is_required: false, order: 4),
        create(:assessment_question, assessment_section: test_section, is_required: false, order: 5)
      ]
    }

    describe '#total_questions' do
      it 'returns total count of questions' do
        expect(test_section.total_questions).to eq(5)
      end
    end

    describe '#required_questions' do
      it 'returns count of required questions' do
        expect(test_section.required_questions).to eq(2)
      end
    end

    describe '#optional_questions' do
      it 'returns count of optional questions' do
        expect(test_section.optional_questions).to eq(3)
      end
    end

    describe '#question_types_summary' do
      it 'returns summary of question types' do
        summary = test_section.question_types_summary
        expect(summary).to be_a(Hash)
        expect(summary.keys).to include('Richtext') # demodulized and humanized
      end
    end

    describe '#can_be_deleted?' do
      context 'when section has no questions' do
        let(:empty_section) { create(:assessment_section, assessment: assessment, name: 'Empty Section', order: 10) }

        it 'returns true' do
          expect(empty_section.can_be_deleted?).to be true
        end
      end

      context 'when section has questions' do
        it 'returns false' do
          expect(test_section.can_be_deleted?).to be false
        end
      end
    end

    describe '#display_name' do
      context 'when name is present' do
        it 'returns the name' do
          test_section.name = 'Introduction'
          expect(test_section.display_name).to eq('Introduction')
        end
      end

      context 'when name is blank' do
        it 'returns formatted order' do
          test_section.name = ''
          test_section.order = 2
          expect(test_section.display_name).to eq('Section 2')
        end
      end
    end
  end

  describe 'callbacks' do
    context 'when creating section without name' do
      it 'auto-generates name' do
        # Clear existing sections to get predictable order
        assessment.assessment_sections.destroy_all

        section = build(:assessment_section, assessment: assessment, name: nil, order: 3)
        section.save!
        # The auto-generation uses calculate_section_number, which for new records uses max_order + 1
        # Since we cleared all sections, max_order is 0, so it becomes 1
        expect(section.name).to eq('Section 1')
      end
    end

    context 'when creating section without order' do
      it 'auto-sets order' do
        # Clear existing sections and create predictable ones
        assessment.assessment_sections.destroy_all
        create(:assessment_section, assessment: assessment, order: 1)
        create(:assessment_section, assessment: assessment, order: 2)

        section = build(:assessment_section, assessment: assessment, order: nil)
        section.save!
        expect(section.order).to eq(3)
      end
    end
  end

  describe 'integration with assessment visibility' do
    let(:user) { create(:user) }
    let(:session) { create(:assessment_response_session, assessment: assessment, user: user) }
    let(:trigger_section) { create(:assessment_section, assessment: assessment, order: 1) }
    let(:trigger_question) { create(:assessment_question, assessment_section: trigger_section, order: 1) }
    let(:conditional_section) { create(:assessment_section, assessment: assessment, order: 2) }
    let(:option) { create(:assessment_question_option, assessment_question: trigger_question) }

    before do
      conditional_section.update!(
        is_conditional: true,
        trigger_question_id: trigger_question.id,
        trigger_response_type: 'option_selected',
        trigger_values: [option.id.to_s],
        operator: 'contains'
      )
    end

    it 'integrates with assessment visibility methods' do
      # Initially hidden
      expect(assessment.visible_sections_for_session(session)).not_to include(conditional_section)

      # Answer trigger question
      response = create(:assessment_question_response,
        assessment_response_session: session,
        assessment_question: trigger_question,
        assessment: assessment
      )
      create(:selected_option,
        assessment_question_response: response,
        assessment_question_option: option
      )

      # Now visible
      expect(assessment.visible_sections_for_session(session)).to include(conditional_section)
    end
  end
end
