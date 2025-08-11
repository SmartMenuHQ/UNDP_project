# == Schema Information
#
# Table name: countries
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE), not null
#  code       :string(3)        not null
#  name       :string           not null
#  region     :string
#  sort_order :integer          default(0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_countries_on_active                 (active)
#  index_countries_on_active_and_sort_order  (active,sort_order)
#  index_countries_on_code                   (code) UNIQUE
#  index_countries_on_region                 (region)
#  index_countries_on_sort_order             (sort_order)
#
class Country < ApplicationRecord
  has_many :users, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, length: { is: 3 }
  validates :code, format: { with: /\A[A-Z]{3}\z/, message: "must be 3 uppercase letters (ISO 3166-1 alpha-3)" }
  validates :region, inclusion: { in: %w[Africa Americas Asia Europe Oceania], allow_blank: true }
  validates :sort_order, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_region, ->(region) { where(region: region) }
  scope :ordered, -> { order(:sort_order, :name) }
  scope :alphabetical, -> { order(:name) }

  # Callbacks
  before_validation :normalize_code
  before_save :set_default_sort_order

  # Class methods
  def self.regions
    %w[Africa Americas Asia Europe Oceania]
  end

  def self.available_for_selection
    active.ordered
  end

  def self.popular_countries
    # Return commonly used countries first
    popular_codes = %w[USA GBR CAN AUS DEU FRA JPN BRA IND CHN]
    popular = where(code: popular_codes, active: true).order(
      Arel.sql("CASE #{popular_codes.map.with_index { |code, i| "WHEN code = '#{code}' THEN #{i}" }.join(' ')} END")
    )
    other = active.where.not(code: popular_codes).alphabetical

    popular.to_a + other.to_a
  end

  def self.seed_common_countries
    countries_data = [
      { name: "United States", code: "USA", region: "Americas", sort_order: 1 },
      { name: "United Kingdom", code: "GBR", region: "Europe", sort_order: 2 },
      { name: "Canada", code: "CAN", region: "Americas", sort_order: 3 },
      { name: "Australia", code: "AUS", region: "Oceania", sort_order: 4 },
      { name: "Germany", code: "DEU", region: "Europe", sort_order: 5 },
      { name: "France", code: "FRA", region: "Europe", sort_order: 6 },
      { name: "Japan", code: "JPN", region: "Asia", sort_order: 7 },
      { name: "Brazil", code: "BRA", region: "Americas", sort_order: 8 },
      { name: "India", code: "IND", region: "Asia", sort_order: 9 },
      { name: "China", code: "CHN", region: "Asia", sort_order: 10 },
      { name: "Spain", code: "ESP", region: "Europe", sort_order: 11 },
      { name: "Italy", code: "ITA", region: "Europe", sort_order: 12 },
      { name: "Mexico", code: "MEX", region: "Americas", sort_order: 13 },
      { name: "Netherlands", code: "NLD", region: "Europe", sort_order: 14 },
      { name: "South Africa", code: "ZAF", region: "Africa", sort_order: 15 }
    ]

    countries_data.each do |country_attrs|
      find_or_create_by(code: country_attrs[:code]) do |country|
        country.assign_attributes(country_attrs)
      end
    end
  end

  # Instance methods
  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  def toggle_status!
    update!(active: !active)
  end

  def users_count
    users.count
  end

  def can_be_deleted?
    users_count == 0
  end

  def display_name
    "#{name} (#{code})"
  end

  def flag_emoji
    # Convert ISO 3166-1 alpha-3 to alpha-2 for emoji (simplified mapping)
    alpha_2_map = {
      'USA' => 'US', 'GBR' => 'GB', 'CAN' => 'CA', 'AUS' => 'AU',
      'DEU' => 'DE', 'FRA' => 'FR', 'JPN' => 'JP', 'BRA' => 'BR',
      'IND' => 'IN', 'CHN' => 'CN', 'ESP' => 'ES', 'ITA' => 'IT',
      'MEX' => 'MX', 'NLD' => 'NL', 'ZAF' => 'ZA'
    }

    alpha_2 = alpha_2_map[code] || code[0..1]
    alpha_2.chars.map { |char| (char.ord + 127397).chr(Encoding::UTF_8) }.join
  rescue
    "🏳️" # Fallback flag
  end

  # Admin management
  def restricted_content_count
    question_count = AssessmentQuestion.where("restricted_countries @> ?", [code].to_json).count
    section_count = AssessmentSection.where("restricted_countries @> ?", [code].to_json).count
    { questions: question_count, sections: section_count }
  end

  private

  def normalize_code
    self.code = code.to_s.upcase.strip if code.present?
  end

  def set_default_sort_order
    if sort_order.zero? && persisted?
      self.sort_order = (self.class.maximum(:sort_order) || 0) + 1
    end
  end
end
