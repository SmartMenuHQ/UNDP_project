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
# Indexes
#
#  index_assessment_sections_on_assessment_id             (assessment_id)
#  index_assessment_sections_on_has_country_restrictions  (has_country_restrictions)
#  index_assessment_sections_on_is_conditional            (is_conditional)
#  index_assessment_sections_on_restricted_countries      (restricted_countries) USING gin
#  index_assessment_sections_on_visibility_conditions     (visibility_conditions) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#
class AssessmentSection < ApplicationRecord
  include ConditionalVisibility
  include CountryRestrictable

  belongs_to :assessment
  has_many :assessment_questions, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :assessment_questions, allow_destroy: true

  # Callbacks (run before validation to set auto-generated values)
  before_validation :auto_generate_name, if: :should_auto_generate_name?
  before_validation :auto_set_order, if: :should_auto_set_order?

  # Validations
  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  validates :order, presence: true, numericality: { greater_than: 0 }
  validates :order, uniqueness: { scope: :assessment_id }

  # Scopes
  scope :ordered, -> { order(:order) }

  # Instance methods
  def total_questions
    assessment_questions.count
  end

  def required_questions
    assessment_questions.where(is_required: true).count
  end

  def optional_questions
    assessment_questions.where(is_required: false).count
  end

  def question_types_summary
    assessment_questions.group(:type).count.transform_keys { |k| k.demodulize.humanize }
  end

  def can_be_deleted?
    assessment_questions.count == 0
  end

  def display_name
    name.presence || "Section #{order}"
  end

  private

  def should_auto_generate_name?
    name.blank?
  end

  def should_auto_set_order?
    order.blank?
  end

  def auto_generate_name
    section_number = calculate_section_number
    self.name = "Section #{section_number}"
  end

  def auto_set_order
    self.order = calculate_section_number
  end

  def calculate_section_number
    if persisted?
      # For existing records, maintain current position
      current_order = self.order || assessment.assessment_sections.count + 1
      current_order
    else
      # For new records, find the next available number
      if id.present?
        existing_sections = assessment.assessment_sections.where.not(id: id)
      else
        existing_sections = assessment.assessment_sections
      end
      max_order = existing_sections.maximum(:order) || 0
      max_order + 1
    end
  end
end
