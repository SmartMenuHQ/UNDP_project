namespace :translation do
  desc "Test both Google Translate and DeepL providers"
  task test_providers: :environment do
    puts "🧪 Testing Translation Providers"
    puts "=" * 50

    # Test data
    test_text = "Hello, how are you?"
    source_locale = :en
    target_locale = :es
    expected_spanish = ["Hola", "¿cómo", "estás"]

    providers = [
      { name: 'Google Translate', provider: 'google', env_key: 'GOOGLE_API_KEY' },
      { name: 'DeepL', provider: 'deepl', env_key: 'DEEPL_AUTH_KEY' }
    ]

    providers.each do |provider_info|
      puts "\n📝 Testing #{provider_info[:name]}"
      puts "-" * 30

      # Check if API key is configured
      unless ENV[provider_info[:env_key]]
        puts "❌ #{provider_info[:env_key]} not configured - skipping #{provider_info[:name]}"
        next
      end

      begin
        # Test with specific provider
        translator = TranslationService.new(provider_info[:provider])

        puts "✅ #{provider_info[:name]} service initialized"
        puts "🔧 Provider available: #{translator.provider_available?}"

        # Test translation
        result = translator.translate_text_between_locales(test_text, source_locale, target_locale)

        if result
          puts "📝 Original: #{test_text}"
          puts "🌍 Translated: #{result}"

          # Simple validation
          contains_expected = expected_spanish.any? { |word| result.downcase.include?(word.downcase) }
          puts "✓ Translation quality: #{contains_expected ? 'Good' : 'Check manually'}"
        else
          puts "❌ Translation failed - no result returned"
        end

      rescue TranslationService::TranslationError => e
        puts "❌ Translation error: #{e.message}"
      rescue TranslationService::UnsupportedProviderError => e
        puts "❌ Provider error: #{e.message}"
      rescue StandardError => e
        puts "❌ Unexpected error: #{e.message}"
      end
    end

    puts "\n🎯 Next Steps:"
    puts "1. Set environment variables:"
    puts "   export GOOGLE_API_KEY=your_google_key"
    puts "   export DEEPL_AUTH_KEY=your_deepl_key"
    puts "2. Choose provider:"
    puts "   export TRANSLATION_PROVIDER=google  # (default)"
    puts "   export TRANSLATION_PROVIDER=deepl"
    puts "3. Enable auto-translation:"
    puts "   export ENABLE_AUTO_TRANSLATION=true"
  end

  desc "Compare translation quality between providers"
  task compare_providers: :environment do
    puts "🔍 Comparing Translation Providers"
    puts "=" * 50

    # Test phrases
    test_phrases = [
      "What is your favorite programming language?",
      "Please select all that apply.",
      "Do you agree with the terms and conditions?",
      "How would you rate your experience?",
      "Thank you for your feedback."
    ]

    target_locales = [:es, :fr, :ja, :it]

    test_phrases.each_with_index do |phrase, index|
      puts "\n📝 Test #{index + 1}: \"#{phrase}\""
      puts "-" * 60

      target_locales.each do |locale|
        puts "\n🌍 Translating to #{locale.upcase}:"

        %w[google deepl].each do |provider|
          env_key = provider == 'google' ? 'GOOGLE_API_KEY' : 'DEEPL_AUTH_KEY'

          unless ENV[env_key]
            puts "  #{provider.capitalize}: ❌ API key not configured"
            next
          end

          begin
            translator = TranslationService.new(provider)
            result = translator.translate_text_between_locales(phrase, :en, locale)
            puts "  #{provider.capitalize}: #{result || 'Failed'}"
          rescue StandardError => e
            puts "  #{provider.capitalize}: ❌ Error - #{e.message}"
          end
        end
      end
    end

    puts "\n💡 Tips:"
    puts "- Compare translations manually for quality"
    puts "- DeepL often provides more natural translations"
    puts "- Google Translate supports more languages"
    puts "- Consider your specific use case and budget"
  end

  desc "Test provider switching"
  task test_switching: :environment do
    puts "🔄 Testing Provider Switching"
    puts "=" * 40

    test_text = "Welcome to our questionnaire system!"

    %w[google deepl].each do |provider|
      puts "\n📝 Testing with #{provider.capitalize}"

      begin
        # Force provider
        translator = TranslationService.new(provider)

        puts "✅ Current provider: #{translator.current_provider}"
        puts "✅ Provider available: #{translator.provider_available?}"

        if translator.provider_available?
          result = translator.translate_text_between_locales(test_text, :en, :es)
          puts "📝 Translation: #{result}"
        else
          puts "❌ Provider not available (check API key)"
        end

      rescue StandardError => e
        puts "❌ Error with #{provider}: #{e.message}"
      end
    end

    puts "\n🔧 Environment Variable Test:"
    original_provider = ENV['TRANSLATION_PROVIDER']

    %w[google deepl invalid].each do |test_provider|
      puts "\n🧪 Testing TRANSLATION_PROVIDER=#{test_provider}"
      ENV['TRANSLATION_PROVIDER'] = test_provider

      begin
        translator = TranslationService.new
        puts "✅ Provider: #{translator.current_provider}"
      rescue TranslationService::UnsupportedProviderError => e
        puts "❌ #{e.message}"
      rescue StandardError => e
        puts "❌ Error: #{e.message}"
      end
    end

    # Restore original
    ENV['TRANSLATION_PROVIDER'] = original_provider
    puts "\n✅ Environment restored"
  end

  desc "Show current translation configuration"
  task show_config: :environment do
    puts "⚙️  Current Translation Configuration"
    puts "=" * 45

    puts "🔧 Settings:"
    puts "  Auto-translation enabled: #{Rails.application.config.auto_translation_enabled}"
    puts "  Translation provider: #{ENV.fetch('TRANSLATION_PROVIDER', 'google')}"
    puts "  Available locales: #{Rails.application.config.i18n.available_locales.join(', ')}"

    puts "\n🔑 API Keys:"
    puts "  Google API Key: #{ENV['GOOGLE_API_KEY'] ? '✅ Set' : '❌ Not set'}"
    puts "  DeepL Auth Key: #{ENV['DEEPL_AUTH_KEY'] ? '✅ Set' : '❌ Not set'}"

    puts "\n🧪 Provider Tests:"
    %w[google deepl].each do |provider|
      begin
        translator = TranslationService.new(provider)
        status = translator.provider_available? ? "✅ Available" : "❌ Not available"
        puts "  #{provider.capitalize}: #{status}"
      rescue StandardError => e
        puts "  #{provider.capitalize}: ❌ Error - #{e.message}"
      end
    end

    puts "\n📖 Usage Examples:"
    puts "  # Use Google Translate (default)"
    puts "  export TRANSLATION_PROVIDER=google"
    puts "  export GOOGLE_API_KEY=your_key"
    puts ""
    puts "  # Use DeepL"
    puts "  export TRANSLATION_PROVIDER=deepl"
    puts "  export DEEPL_AUTH_KEY=your_key"
  end
end
