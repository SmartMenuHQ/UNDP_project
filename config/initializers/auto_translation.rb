# Auto-translation configuration
# This initializer configures the automatic translation feature for questions and options

Rails.application.configure do
  # Enable auto-translation in production or when explicitly enabled
  # Set ENABLE_AUTO_TRANSLATION=true in your environment to enable in development/test
  config.auto_translation_enabled = Rails.env.production? || ENV['ENABLE_AUTO_TRANSLATION'] == 'true'

  # Get translation provider (default: google)
  translation_provider = ENV.fetch('TRANSLATION_PROVIDER', 'google').downcase

  # Log auto-translation status
  if config.auto_translation_enabled
    Rails.logger.info "🌍 Auto-translation is ENABLED"
    Rails.logger.info "🔧 Translation provider: #{translation_provider}"
    Rails.logger.info "🌐 Available locales: #{I18n.available_locales.join(', ')}"

    # Check provider configuration
    case translation_provider
    when 'google'
      if ENV['GOOGLE_API_KEY'].present?
        Rails.logger.info "✅ Google Translate API key configured"
      else
        Rails.logger.warn "⚠️  Google Translate API key not found (GOOGLE_API_KEY)"
      end
    when 'deepl'
      if ENV['DEEPL_AUTH_KEY'].present?
        Rails.logger.info "✅ DeepL API key configured"
      else
        Rails.logger.warn "⚠️  DeepL API key not found (DEEPL_AUTH_KEY)"
      end
    else
      Rails.logger.error "❌ Unsupported translation provider: #{translation_provider}"
      Rails.logger.info "   Supported providers: google, deepl"
    end
  else
    Rails.logger.info "🌍 Auto-translation is DISABLED"
    Rails.logger.info "   To enable in development, set: ENABLE_AUTO_TRANSLATION=true"
  end
end
