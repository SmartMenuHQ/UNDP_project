require "google/cloud/translate/v2"
require "deepl"

class TranslationService
  class TranslationError < StandardError; end
  class UnsupportedProviderError < StandardError; end

  SUPPORTED_PROVIDERS = %w[google deepl].freeze
  DEFAULT_PROVIDER = 'google'.freeze

  def initialize(provider = nil)
    @provider = provider || ENV.fetch('TRANSLATION_PROVIDER', DEFAULT_PROVIDER).downcase

    unless SUPPORTED_PROVIDERS.include?(@provider)
      raise UnsupportedProviderError, "Unsupported provider: #{@provider}. Supported: #{SUPPORTED_PROVIDERS.join(', ')}"
    end

    @translator = initialize_translator
  end

  # Public method for translating text between locales
  def translate_text_between_locales(text, source_locale, target_locale)
    return nil if text.blank?

    source_lang = normalize_locale(source_locale)
    target_lang = normalize_locale(target_locale)

    return text if source_lang == target_lang

    case @provider
    when 'google'
      translate_with_google(text, source_lang, target_lang)
    when 'deepl'
      translate_with_deepl(text, source_lang, target_lang)
    end
  rescue StandardError => e
    Rails.logger.error "Translation error with #{@provider} for '#{text}' (#{source_locale} -> #{target_locale}): #{e.message}"
    raise TranslationError, "Translation failed with #{@provider}: #{e.message}"
  end

  # Translate a single record (AssessmentQuestion or AssessmentQuestionOption)
  def translate_record(record, source_locale = :en, target_locales = nil)
    target_locales ||= available_locales - [source_locale]

    raise TranslationError, "Record must respond to text" unless record.respond_to?(:text)

    source_text = record.text(locale: source_locale)
    return false if source_text.blank?

    target_locales.each do |target_locale|
      next if record.text(locale: target_locale).present? # Skip if translation already exists

      translated_text = translate_text(source_text, source_locale, target_locale)

      if translated_text.present?
        record.update!(text: translated_text, locale: target_locale)
        Rails.logger.info "Translated #{record.class.name} ##{record.id} to #{target_locale} using #{@provider}"
      end
    end

    true
  rescue StandardError => e
    Rails.logger.error "Translation API error with #{@provider}: #{e.message}"
    raise TranslationError, "Translation failed with #{@provider}: #{e.message}"
  end

  # Translate all questions in an assessment
  def translate_assessment(assessment, source_locale = :en, target_locales = nil)
    target_locales ||= available_locales - [source_locale]

    results = {
      questions: { success: 0, failed: 0 },
      options: { success: 0, failed: 0 },
      provider: @provider
    }

    # Translate questions
    assessment.assessment_questions.find_each do |question|
      if translate_record(question, source_locale, target_locales)
        results[:questions][:success] += 1
      else
        results[:questions][:failed] += 1
      end
    end

    # Translate question options
    assessment.assessment_question_options.find_each do |option|
      if translate_record(option, source_locale, target_locales)
        results[:options][:success] += 1
      else
        results[:options][:failed] += 1
      end
    end

    results
  end

  # Translate a single question and its options
  def translate_question_with_options(question, source_locale = :en, target_locales = nil)
    target_locales ||= available_locales - [source_locale]

    results = { question: false, options: [], provider: @provider }

    # Translate question text
    results[:question] = translate_record(question, source_locale, target_locales)

    # Translate options if question has them
    if question.respond_to?(:option) && question.option.present?
      question.option.each do |option|
        option_result = translate_record(option, source_locale, target_locales)
        results[:options] << { id: option.id, success: option_result }
      end
    end

    results
  end

  # Batch translate multiple records
  def translate_batch(records, source_locale = :en, target_locales = nil)
    target_locales ||= available_locales - [source_locale]

    results = { success: 0, failed: 0, errors: [], provider: @provider }

    records.each do |record|
      begin
        if translate_record(record, source_locale, target_locales)
          results[:success] += 1
        else
          results[:failed] += 1
        end
      rescue TranslationError => e
        results[:failed] += 1
        results[:errors] << { record: "#{record.class.name} ##{record.id}", error: e.message }
      end
    end

    results
  end

  # Get current provider
  def current_provider
    @provider
  end

  # Check if provider is available
  def provider_available?
    case @provider
    when 'google'
      ENV['GOOGLE_API_KEY'].present?
    when 'deepl'
      ENV['DEEPL_AUTH_KEY'].present?
    else
      false
    end
  end

  private

  def initialize_translator
    case @provider
    when 'google'
      unless ENV['GOOGLE_API_KEY']
        raise TranslationError, "GOOGLE_API_KEY environment variable not set"
      end
      Google::Cloud::Translate::V2.new(key: ENV['GOOGLE_API_KEY'])
    when 'deepl'
      unless ENV['DEEPL_AUTH_KEY']
        raise TranslationError, "DEEPL_AUTH_KEY environment variable not set"
      end
      DeepL.configure { |config| config.auth_key = ENV['DEEPL_AUTH_KEY'] }
      DeepL
    end
  end

  def translate_with_google(text, source_lang, target_lang)
    result = @translator.translate(text, from: source_lang, to: target_lang)
    result.text
  rescue Google::Cloud::Error => e
    raise TranslationError, "Google Translate error: #{e.message}"
  end

  def translate_with_deepl(text, source_lang, target_lang)
    result = @translator.translate(text, source_lang, target_lang)
    result.text
  rescue DeepL::Exceptions::Error => e
    raise TranslationError, "DeepL error: #{e.message}"
  end

  def translate_text(text, source_locale, target_locale)
    return nil if text.blank?

    source_lang = normalize_locale(source_locale)
    target_lang = normalize_locale(target_locale)

    return text if source_lang == target_lang

    case @provider
    when 'google'
      translate_with_google(text, source_lang, target_lang)
    when 'deepl'
      translate_with_deepl(text, source_lang, target_lang)
    end
  rescue StandardError => e
    Rails.logger.error "Translation error with #{@provider} for '#{text}' (#{source_locale} -> #{target_locale}): #{e.message}"
    nil
  end

  def normalize_locale(locale)
    # Convert Rails locale codes to provider-specific language codes
    locale_str = locale.to_s

    case @provider
    when 'google'
      # Google Translate language codes
      case locale_str
      when 'en' then 'en'
      when 'es' then 'es'
      when 'ja' then 'ja'
      when 'it' then 'it'
      when 'fr' then 'fr'
      else locale_str
      end
    when 'deepl'
      # DeepL language codes (more specific)
      case locale_str
      when 'en' then 'EN-US'
      when 'es' then 'ES'
      when 'ja' then 'JA'
      when 'it' then 'IT'
      when 'fr' then 'FR'
      else
        # DeepL might not support all locales, fallback to the locale string
        locale_str.upcase
      end
    else
      locale_str
    end
  end

  def available_locales
    Rails.application.config.i18n.available_locales
  end
end
