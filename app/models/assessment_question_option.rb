# == Schema Information
#
# Table name: assessment_question_options
#
#  id                     :bigint           not null, primary key
#  default_locale         :string
#  metadata               :jsonb
#  order                  :integer
#  text                   :jsonb
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  assessment_id          :bigint           not null
#  assessment_question_id :bigint           not null
#
# Indexes
#
#  index_assessment_question_options_on_assessment_id           (assessment_id)
#  index_assessment_question_options_on_assessment_question_id  (assessment_question_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (assessment_question_id => assessment_questions.id)
#
class AssessmentQuestionOption < ApplicationRecord
  extend Mobility

  belongs_to :assessment
  belongs_to :assessment_question

  translates :text, backend: :jsonb

  # Validations
  validates :text, presence: true
  validates :order, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :ordered, -> { order(:order) }

  # Callbacks
  after_initialize :ensure_text_initialized
  after_save :queue_translation_job, if: :should_auto_translate?

  private

  def should_auto_translate?
    saved_change_to_text? && text.present?
  end

  def queue_translation_job
    return unless Rails.application.config.auto_translation_enabled

    source_locale = default_locale || 'en'

    # Skip if the source locale is not available
    return unless Rails.application.config.i18n.available_locales.include?(source_locale.to_sym)

    # Queue the translation job
    TranslationJob.perform_later(self.class.name, id, source_locale)

    Rails.logger.info "Queued translation job for #{self.class.name} ##{id} from #{source_locale}"
  end

  def ensure_text_initialized
    self.text ||= {}
  end
end
