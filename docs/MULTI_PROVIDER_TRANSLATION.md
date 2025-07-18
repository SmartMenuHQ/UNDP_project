# Multi-Provider Translation System Documentation

## Overview

The translation system now supports both **Google Translate** and **DeepL** as translation providers. You can switch between providers using environment variables, with Google Translate as the default. This gives you flexibility in choosing the best translation service for your needs.

## Supported Providers

### Google Translate
- **Default provider**
- Wide language support (100+ languages)
- Competitive pricing
- Good general-purpose translations
- Neural machine translation

### DeepL
- **Premium option**
- Excellent translation quality
- More natural, context-aware translations
- Supports 30+ languages
- Higher accuracy for European languages

## Configuration

### Environment Variables

```bash
# Translation provider (default: google)
export TRANSLATION_PROVIDER=google  # or deepl

# Google Translate API key
export GOOGLE_API_KEY=your_google_api_key

# DeepL API key
export DEEPL_AUTH_KEY=your_deepl_auth_key

# Enable auto-translation
export ENABLE_AUTO_TRANSLATION=true
```

### Provider Selection

```bash
# Use Google Translate (default)
export TRANSLATION_PROVIDER=google

# Use DeepL
export TRANSLATION_PROVIDER=deepl
```

## Setup Instructions

### Google Translate Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the Cloud Translation API
4. Create credentials (API Key)
5. Set environment variable:
   ```bash
   export GOOGLE_API_KEY=your_api_key_here
   ```

### DeepL Setup

1. Go to [DeepL API](https://www.deepl.com/pro-api)
2. Sign up for DeepL API account
3. Get your authentication key from the account page
4. Set environment variable:
   ```bash
   export DEEPL_AUTH_KEY=your_auth_key_here
   ```

## Usage

### Automatic Provider Selection

```ruby
# Uses provider from TRANSLATION_PROVIDER env var (default: google)
translator = TranslationService.new

# Check current provider
puts translator.current_provider  # "google" or "deepl"

# Check if provider is available
puts translator.provider_available?  # true/false
```

### Force Specific Provider

```ruby
# Force Google Translate
google_translator = TranslationService.new('google')

# Force DeepL
deepl_translator = TranslationService.new('deepl')
```

### Translation Examples

```ruby
# Basic text translation
translator = TranslationService.new
result = translator.translate_text_between_locales(
  "Hello, how are you?", :en, :es
)

# Google Translate result: "Hola, ¿cómo estás?"
# DeepL result: "Hola, ¿cómo está usted?"
```

### Background Jobs

The background translation system automatically uses the configured provider:

```ruby
# Create question - uses configured provider
question = AssessmentQuestions::MultipleChoice.create!(
  text: "What is your favorite programming language?",
  default_locale: "en",
  assessment: assessment,
  assessment_section: section
)

# TranslationJob will use TRANSLATION_PROVIDER setting
```

## Language Code Mapping

### Google Translate
- English: `en`
- Spanish: `es`
- Japanese: `ja`
- Italian: `it`
- French: `fr`

### DeepL
- English: `EN-US`
- Spanish: `ES`
- Japanese: `JA`
- Italian: `IT`
- French: `FR`

The service automatically handles the mapping between Rails locales and provider-specific language codes.

## Testing

### Test Both Providers

```bash
# Test both providers with sample text
rails translation:test_providers

# Compare translation quality
rails translation:compare_providers

# Test provider switching
rails translation:test_switching

# Show current configuration
rails translation:show_config
```

### Test Results Example

```
🧪 Testing Translation Providers
==================================================

📝 Testing Google Translate
------------------------------
✅ Google Translate service initialized
🔧 Provider available: true
📝 Original: Hello, how are you?
🌍 Translated: Hola, ¿cómo estás?
✓ Translation quality: Good

📝 Testing DeepL
------------------------------
✅ DeepL service initialized
🔧 Provider available: true
📝 Original: Hello, how are you?
🌍 Translated: Hola, ¿cómo está usted?
✓ Translation quality: Good
```

## Provider Comparison

| Feature | Google Translate | DeepL |
|---------|------------------|-------|
| **Language Support** | 100+ languages | 30+ languages |
| **Quality** | Good | Excellent |
| **Speed** | Fast | Fast |
| **Pricing** | $20/1M characters | €5.49/500k characters |
| **Context Awareness** | Good | Excellent |
| **Technical Text** | Good | Better |
| **Casual Text** | Good | More natural |

## Error Handling

### Provider-Specific Errors

```ruby
begin
  translator = TranslationService.new('deepl')
  result = translator.translate_text_between_locales(text, :en, :es)
rescue TranslationService::UnsupportedProviderError => e
  puts "Provider error: #{e.message}"
rescue TranslationService::TranslationError => e
  puts "Translation error: #{e.message}"
end
```

### Fallback Strategy

```ruby
def translate_with_fallback(text, source, target)
  # Try DeepL first
  begin
    translator = TranslationService.new('deepl')
    return translator.translate_text_between_locales(text, source, target)
  rescue TranslationService::TranslationError
    Rails.logger.warn "DeepL failed, falling back to Google Translate"
  end

  # Fallback to Google Translate
  begin
    translator = TranslationService.new('google')
    return translator.translate_text_between_locales(text, source, target)
  rescue TranslationService::TranslationError => e
    Rails.logger.error "Both providers failed: #{e.message}"
    nil
  end
end
```

## Monitoring and Logging

### Log Messages

```ruby
# Provider information
Rails.logger.info "🔧 Translation provider: google"
Rails.logger.info "✅ Google Translate API key configured"

# Translation results
Rails.logger.info "Translated AssessmentQuestion #123 to es using google"
Rails.logger.info "Completed translation for AssessmentQuestion #123"

# Errors
Rails.logger.error "Translation failed with google: API quota exceeded"
Rails.logger.warn "⚠️  DeepL API key not found (DEEPL_AUTH_KEY)"
```

### Check Configuration

```bash
# See current configuration
rails translation:show_config
```

## Performance Considerations

### API Limits

#### Google Translate
- Default quota: 500,000 characters/month (free tier)
- Paid: $20 per 1M characters
- Rate limit: 100 requests/100 seconds

#### DeepL
- Free tier: 500,000 characters/month
- Pro: Starting at €5.49/month for 500k characters
- Rate limit: Varies by plan

### Optimization Tips

1. **Cache translations**: Avoid re-translating the same content
2. **Batch requests**: Group multiple translations when possible
3. **Monitor usage**: Track API consumption to avoid overages
4. **Provider selection**: Choose based on quality vs. cost needs

## Best Practices

### Development

```bash
# Development environment
export TRANSLATION_PROVIDER=google
export GOOGLE_API_KEY=your_dev_key
export ENABLE_AUTO_TRANSLATION=true
```

### Production

```bash
# Production environment
export TRANSLATION_PROVIDER=deepl  # or google
export DEEPL_AUTH_KEY=your_prod_key
# Auto-translation enabled by default in production
```

### Quality Assurance

1. **Test both providers** with your specific content
2. **Review translations** for technical accuracy
3. **Consider domain-specific** terminology
4. **Monitor costs** and usage patterns
5. **Have fallback strategy** in case of provider issues

## Migration Between Providers

### Switching Providers

```bash
# Current: Google Translate
export TRANSLATION_PROVIDER=google

# Switch to DeepL
export TRANSLATION_PROVIDER=deepl
export DEEPL_AUTH_KEY=your_deepl_key

# Restart application to pick up new configuration
```

### Re-translating Existing Content

```ruby
# Force re-translation with new provider
assessment = Assessment.find(1)
translator = TranslationService.new('deepl')  # Force new provider

# Clear existing translations (optional)
assessment.assessment_questions.each do |question|
  Rails.application.config.i18n.available_locales.each do |locale|
    next if locale == :en
    Mobility.with_locale(locale) { question.update!(text: nil) }
  end
end

# Re-translate with new provider
results = translator.translate_assessment(assessment)
```

## Troubleshooting

### Common Issues

1. **Provider not available**
   - Check API key configuration
   - Verify environment variable names
   - Test connectivity to provider API

2. **Translation quality issues**
   - Try alternative provider
   - Check source text quality
   - Verify language codes

3. **API quota exceeded**
   - Monitor usage in provider dashboard
   - Implement rate limiting
   - Consider upgrading plan

### Debug Commands

```bash
# Show all configuration
rails translation:show_config

# Test specific provider
TRANSLATION_PROVIDER=deepl rails translation:test_providers

# Compare providers side by side
rails translation:compare_providers
```

## Cost Optimization

### Strategies

1. **Choose appropriate provider** based on volume and quality needs
2. **Implement caching** to avoid duplicate translations
3. **Use background jobs** to batch translations
4. **Monitor usage** to stay within quotas
5. **Consider hybrid approach**: DeepL for important content, Google for bulk

### Usage Tracking

```ruby
# Track translation requests
class TranslationService
  def translate_text_between_locales(text, source_locale, target_locale)
    # Log usage for monitoring
    Rails.logger.info "Translation request: #{text.length} chars, #{@provider}, #{source_locale}->#{target_locale}"

    # ... existing translation logic
  end
end
```

This multi-provider system gives you the flexibility to choose the best translation service for your specific needs while maintaining a consistent interface throughout your application.
