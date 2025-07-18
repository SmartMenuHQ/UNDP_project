# -*- SkipSchemaAnnotations
module AssessmentQuestions
  class BooleanType < AssessmentQuestion
    has_many :option, class_name: 'AssessmentQuestionOption', dependent: :destroy

    accepts_nested_attributes_for :option, allow_destroy: true

    after_create :create_boolean_options

    private

    def create_boolean_options
      source_locale = default_locale || 'en'

      # Create options with localized text in the source locale
      Mobility.with_locale(source_locale.to_sym) do
        option.create!([
          { text: I18n.t('true'), order: 1, assessment: assessment, default_locale: source_locale },
          { text: I18n.t('false'), order: 2, assessment: assessment, default_locale: source_locale }
        ])
      end
    end
  end
end
