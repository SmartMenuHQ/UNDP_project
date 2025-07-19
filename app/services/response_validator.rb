class ResponseValidator
  def initialize(response)
    @response = response
    @question = response.assessment_question
    @errors = response.errors
  end

  def validate!
    return unless @question

    rules = @question.validation_rule_set
    return if rules.blank?

    rules.each do |rule_name, rule_config|
      validation_method = "validate_#{rule_name}"
      if respond_to?(validation_method, true)
        send(validation_method, rule_config)
      end
    end
  end

  private

  attr_reader :response, :question, :errors

  # Alias for easier access
  def assessment_question
    @question
  end

  # Helper method to handle message translation
  # If message looks like an I18n key, translate it with provided options
  # Otherwise use the message as-is (already translated)
  def translate_message(message, options = {})
    # Check if message looks like an I18n key (contains dots and starts with letter)
    if message =~ /^[a-z_]+\.[a-z_\.]+$/
      I18n.t(message, **options)
    else
      message
    end
  end

  def selected_options
    @response.selected_options
  end

  def value
    @response.value
  end

  def has_value?
    @response.has_value?
  end

  # Validation rule methods
  def validate_required(config)
    case assessment_question.type
    when "AssessmentQuestions::MultipleChoice", "AssessmentQuestions::Radio", "AssessmentQuestions::BooleanType"
      if selected_options.count == 0
        message = config["message"] || "validation_errors.required"
        errors.add(:base, translate_message(message))
      end
    else
      if !has_value?
        message = config["message"] || "validation_errors.required"
        errors.add(:base, translate_message(message))
      end
    end
  end

  def validate_min_length(config)
    text_val = value&.dig("text").to_s
    min = config["value"].to_i

    if text_val.length < min
      message = config["message"] || "validation_errors.min_length"
      errors.add(:base, translate_message(message, count: min))
    end
  end

  def validate_max_length(config)
    text_val = value&.dig("text").to_s
    max = config["value"].to_i

    if text_val.length > max
      message = config["message"] || "validation_errors.max_length"
      errors.add(:base, translate_message(message, count: max))
    end
  end

  def validate_email_format(config)
    email_val = value&.dig("text")
    return if email_val.blank?

    unless email_val.match?(URI::MailTo::EMAIL_REGEXP)
      message = config["message"] || "validation_errors.email_format"
      errors.add(:base, translate_message(message))
    end
  end

  def validate_url_format(config)
    url_val = value&.dig("text")
    return if url_val.blank?

    begin
      uri = URI.parse(url_val)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        message = config["message"] || "validation_errors.url_format"
        errors.add(:base, translate_message(message))
      end
    rescue URI::InvalidURIError
      message = config["message"] || "validation_errors.url_format"
      errors.add(:base, translate_message(message))
    end
  end

  def validate_number_range(config)
    num_val = value&.dig("number") || value&.dig("rating") || value&.dig("range")
    return if num_val.blank?

    min = config["min"]
    max = config["max"]

    if min && max && (num_val < min || num_val > max)
      message = config["message"] || "validation_errors.number_range"
      errors.add(:base, translate_message(message, min: min, max: max))
    elsif min && num_val < min
      message = config["message"] || "validation_errors.number_min"
      errors.add(:base, translate_message(message, min: min))
    elsif max && num_val > max
      message = config["message"] || "validation_errors.number_max"
      errors.add(:base, translate_message(message, max: max))
    end
  end

  def validate_date_range(config)
    date_val = value&.dig("date") || value&.dig("datetime") || value&.dig("date_range")
    return if date_val.blank?

    begin
      parsed_date = Date.parse(date_val.to_s)

      if config["min_date"]
        min_date = Date.parse(config["min_date"])
        if parsed_date < min_date
          message = config["message"] || "validation_errors.date_after"
          errors.add(:base, translate_message(message, date: min_date.strftime("%B %d, %Y")))
        end
      end

      if config["max_date"]
        max_date = Date.parse(config["max_date"])
        if parsed_date > max_date
          message = config["message"] || "validation_errors.date_before"
          errors.add(:base, translate_message(message, date: max_date.strftime("%B %d, %Y")))
        end
      end
    rescue Date::Error
      message = config["message"] || "validation_errors.invalid_date"
      errors.add(:base, translate_message(message))
    end
  end

  def validate_future_date(config)
    date_val = value&.dig("date") || value&.dig("datetime")
    return if date_val.blank?

    begin
      parsed_date = Date.parse(date_val.to_s)
      if parsed_date <= Date.current
        message = config["message"] || "validation_errors.future_date"
        errors.add(:base, translate_message(message))
      end
    rescue Date::Error
      message = config["message"] || "validation_errors.invalid_date"
      errors.add(:base, translate_message(message))
    end
  end

  def validate_past_date(config)
    date_val = value&.dig("date") || value&.dig("datetime")
    return if date_val.blank?

    begin
      parsed_date = Date.parse(date_val.to_s)
      if parsed_date >= Date.current
        message = config["message"] || "validation_errors.past_date"
        errors.add(:base, translate_message(message))
      end
    rescue Date::Error
      message = config["message"] || "validation_errors.invalid_date"
      errors.add(:base, translate_message(message))
    end
  end

  def validate_integer_only(config)
    num_val = value&.dig("number") || value&.dig("rating") || value&.dig("range")
    return if num_val.blank?

    unless num_val.is_a?(Integer) || (num_val.is_a?(String) && num_val.match?(/^\d+$/))
      message = config["message"] || "validation_errors.integer_only"
      errors.add(:base, translate_message(message))
    end
  end

  def validate_regex_pattern(config)
    text_val = value&.dig("text")
    return if text_val.blank?

    pattern = config["pattern"]
    return unless pattern.present?

    begin
      regex = Regexp.new(pattern)
      unless text_val.match?(regex)
        message = config["message"] || "validation_errors.pattern_mismatch"
        errors.add(:base, translate_message(message))
      end
    rescue RegexpError
      errors.add(:base, translate_message("validation_errors.pattern_config_error"))
    end
  end

  def validate_file_size(config)
    file_size = value&.dig("size")
    return if file_size.blank?

    max_size = config["max_size"]
    return unless max_size.present?

    if file_size.to_i > max_size.to_i
      max_size_human = ActiveSupport::NumberHelper.number_to_human_size(max_size)
      message = config["message"] || "validation_errors.file_size_exceeded"
      errors.add(:base, translate_message(message, size: max_size_human))
    end
  end

  def validate_file_type(config)
    content_type = value&.dig("content_type")
    filename = value&.dig("filename")
    return if content_type.blank? && filename.blank?

    allowed_types = config["allowed_types"]
    return unless allowed_types.present?

    allowed_types = Array(allowed_types)

    # Check by content type
    if content_type.present?
      unless allowed_types.any? { |type| content_type.include?(type) }
        message = config["message"] || "validation_errors.file_type_not_allowed"
        errors.add(:base, translate_message(message, type: content_type))
        return
      end
    end

    # Check by file extension
    if filename.present?
      extension = File.extname(filename).downcase
      allowed_extensions = allowed_types.map { |type| type.split("/").last.downcase }

      unless allowed_extensions.include?(extension.delete("."))
        message = config["message"] || "validation_errors.file_extension_not_allowed"
        errors.add(:base, translate_message(message, extension: extension))
      end
    end
  end

  # Selection-based validation methods
  def validate_min_selections(config)
    selection_count = selected_options.count
    min = config["value"].to_i

    if selection_count < min
      message = config["message"] || "validation_errors.min_selections"
      errors.add(:base, translate_message(message, count: min))
    end
  end

  def validate_max_selections(config)
    selection_count = selected_options.count
    max = config["value"].to_i

    if selection_count > max
      message = config["message"] || "validation_errors.max_selections"
      errors.add(:base, translate_message(message, count: max))
    end
  end

  # Date format validation methods
  def validate_date_format(config)
    date_val = value&.dig("date")
    return if date_val.blank?

    begin
      Date.parse(date_val)
    rescue Date::Error
      message = config["message"] || "validation_errors.date_format"
      errors.add(:base, translate_message(message))
    end
  end

  def validate_datetime_format(config)
    datetime_val = value&.dig("datetime")
    return if datetime_val.blank?

    begin
      DateTime.parse(datetime_val)
    rescue Date::Error
      message = config["message"] || "validation_errors.datetime_format"
      errors.add(:base, translate_message(message))
    end
  end

  def validate_year_range(config)
    year_val = value&.dig("year")
    return if year_val.blank?

    year = year_val.to_i
    min_year = config["min_year"].to_i
    max_year = config["max_year"].to_i

    if year < min_year || year > max_year
      message = config["message"] || "validation_errors.year_range"
      errors.add(:base, translate_message(message, min_year: min_year, max_year: max_year))
    end
  end
end
