module CountryRestrictable
  extend ActiveSupport::Concern

  included do
    # Store accessor for country restrictions
    store_accessor :restricted_countries, :blacklisted_country_codes

    # Scopes
    scope :with_country_restrictions, -> { where(has_country_restrictions: true) }
    scope :without_country_restrictions, -> { where(has_country_restrictions: false) }
    scope :accessible_to_country, ->(country_code) {
            where(
              "(has_country_restrictions = false) OR " \
              "(restricted_countries = '[]') OR " \
              "(NOT (restricted_countries @> ?))",
              [country_code].to_json
            )
          }
    scope :restricted_for_country, ->(country_code) {
            where(
              "(has_country_restrictions = true) AND " \
              "(restricted_countries @> ?)",
              [country_code].to_json
            )
          }

    # Validations
    validate :restricted_countries_are_valid, if: :has_country_restrictions?

    # Callbacks
    before_save :update_restriction_flag
  end

  # Add country restrictions
  def add_country_restriction(country_codes)
    country_codes = Array(country_codes)
    current_restrictions = self.restricted_countries || []

    self.restricted_countries = (current_restrictions + country_codes).uniq
    self.has_country_restrictions = self.restricted_countries.any?
  end

  # Remove country restrictions
  def remove_country_restriction(country_codes)
    country_codes = Array(country_codes)
    current_restrictions = self.restricted_countries || []

    self.restricted_countries = current_restrictions - country_codes
    self.has_country_restrictions = self.restricted_countries.any?
  end

  # Clear all restrictions
  def clear_country_restrictions
    self.restricted_countries = []
    self.has_country_restrictions = false
  end

  # Check if accessible to a specific country
  def accessible_to_country?(country_code)
    return true unless has_country_restrictions?
    return true if restricted_countries.blank?

    !restricted_countries.include?(country_code)
  end

  # Check if restricted for a specific country
  def restricted_for_country?(country_code)
    return false unless has_country_restrictions?
    return false if restricted_countries.blank?

    restricted_countries.include?(country_code)
  end

  # Check if accessible to a user
  def accessible_to_user?(user)
    return true unless user&.country
    accessible_to_country?(user.country.code)
  end

  # Get list of restricted country names
  def restricted_country_names
    return [] unless has_country_restrictions?

    Country.where(code: restricted_countries).pluck(:name)
  end

  # Get human-readable restriction description
  def restriction_description
    return "Available worldwide" unless has_country_restrictions?
    return "Available worldwide" if restricted_countries.blank?

    country_names = restricted_country_names
    case country_names.length
    when 0
      "Available worldwide"
    when 1
      "Restricted in #{country_names.first}"
    when 2
      "Restricted in #{country_names.join(" and ")}"
    else
      "Restricted in #{country_names[0..-2].join(", ")} and #{country_names.last}"
    end
  end

  # Bulk operations
  def self.included(base)
    super

    base.extend(ClassMethods)
  end

  module ClassMethods
    # Add restrictions to multiple items
    def add_country_restrictions_to_all(items, country_codes)
      items.each { |item| item.add_country_restriction(country_codes) }
      items.each(&:save!)
    end

    # Remove restrictions from multiple items
    def remove_country_restrictions_from_all(items, country_codes)
      items.each { |item| item.remove_country_restriction(country_codes) }
      items.each(&:save!)
    end

    # Clear all restrictions from multiple items
    def clear_all_country_restrictions(items)
      items.each(&:clear_country_restrictions)
      items.each(&:save!)
    end

    # Get restriction statistics
    def restriction_statistics
      total = count
      with_restrictions = with_country_restrictions.count

      {
        total: total,
        with_restrictions: with_restrictions,
        without_restrictions: total - with_restrictions,
        restriction_percentage: total > 0 ? (with_restrictions.to_f / total * 100).round(1) : 0,
      }
    end

    # Get items restricted for specific country
    def restricted_for_country_with_details(country_code)
      restricted_items = restricted_for_country(country_code)

      restricted_items.map do |item|
        {
          id: item.id,
          title: item.respond_to?(:text) ? item.text : item.name,
          type: item.class.name,
          restricted_countries: item.restricted_country_names,
          restriction_count: item.restricted_countries.length,
        }
      end
    end
  end

  private

  def restricted_countries_are_valid
    return unless has_country_restrictions? && restricted_countries.present?

    invalid_codes = restricted_countries - Country.pluck(:code)

    if invalid_codes.any?
      errors.add(:restricted_countries, "contains invalid country codes: #{invalid_codes.join(", ")}")
    end
  end

  def update_restriction_flag
    if restricted_countries.present?
      self.has_country_restrictions = true
    else
      self.has_country_restrictions = false
    end
  end
end
