class TranslationJob < ApplicationJob
  queue_as :default

  def perform(record_type, record_id, source_locale = 'en')
    record = record_type.constantize.find(record_id)
    source_locale = source_locale.to_sym

    # Get available target locales (excluding source locale)
    target_locales = Rails.application.config.i18n.available_locales - [source_locale]
    return if target_locales.empty?

    # Get source text using Mobility
    source_text = nil
    Mobility.with_locale(source_locale) do
      source_text = record.text
    end

    return if source_text.blank?

    # Initialize translation service
    translator = TranslationService.new

    # Translate to each target locale using proper Mobility patterns
    target_locales.each do |target_locale|
      begin
        # Skip if translation already exists
        existing_translation = nil
        Mobility.with_locale(target_locale) do
          existing_translation = record.text
        end

        next if existing_translation.present?

        # Use TranslationService to translate text
        translated_text = translator.translate_text_between_locales(source_text, source_locale, target_locale)

        if translated_text.present?
          # Set the translated text using Mobility
          Mobility.with_locale(target_locale) do
            record.text = translated_text
          end

          Rails.logger.info "Translated #{record.class.name} ##{record.id} to #{target_locale}: #{translated_text}"
        end

      rescue TranslationService::TranslationError => e
        Rails.logger.error "Translation failed for #{record.class.name} ##{record.id} to #{target_locale}: #{e.message}"
      rescue StandardError => e
        Rails.logger.error "Unexpected error translating #{record.class.name} ##{record.id} to #{target_locale}: #{e.message}"
      end
    end

    # Save all translations at once
    record.save!

    Rails.logger.info "Completed translation for #{record.class.name} ##{record.id}"

  rescue StandardError => e
    Rails.logger.error "Translation job failed for #{record_type} ##{record_id}: #{e.message}"
    raise e
  end
end
