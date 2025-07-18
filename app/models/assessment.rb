# == Schema Information
#
# Table name: assessments
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE)
#  description :text
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Assessment < ApplicationRecord
  has_many :assessment_sections, dependent: :destroy
  has_many :assessment_questions, dependent: :destroy
  has_many :assessment_question_options, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :assessment_sections, allow_destroy: true

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  validates :description, length: { maximum: 1000 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def total_questions
    assessment_questions.count
  end

  def total_sections
    assessment_sections.count
  end

  def completion_percentage
    return 0 if total_questions == 0
    # This would be calculated based on actual responses in a real app
    0
  end

  def status
    active? ? 'Active' : 'Draft'
  end

  def status_color
    active? ? 'green' : 'yellow'
  end

  def formatted_created_at
    created_at.strftime('%B %d, %Y')
  end

  def can_be_deleted?
    # Add business logic here - e.g., can't delete if has responses
    true
  end
end
