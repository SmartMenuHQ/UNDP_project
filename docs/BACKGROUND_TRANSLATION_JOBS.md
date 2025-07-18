# Background Translation Jobs Documentation

## Overview

The background translation system automatically translates assessment questions and options to all available locales using Google Translate API. This implementation uses Rails background jobs and the correct Mobility framework patterns for optimal performance and reliability.

## How It Works

### Translation Flow

1. **Question/Option is saved** with text content
2. **Callback queues background job** if text has changed
3. **Job processes asynchronously** using Google Translate API
4. **Mobility framework** handles locale switching and storage
5. **Translations are saved** to the database
6. **Content is accessible** in all supported languages

### Key Components

- **TranslationJob**: Background job that handles the translation process
- **Model Callbacks**: Queue translation jobs after save
- **Mobility Integration**: Proper locale handling and storage
- **Google Translate API**: Actual translation service

## Configuration

### Environment Variables

```bash
# Enable auto-translation
export ENABLE_AUTO_TRANSLATION=true

# Google Translate API key (required)
export GOOGLE_API_KEY=your_api_key_here
```

### Rails Configuration

```ruby
# config/initializers/auto_translation.rb
Rails.application.config.auto_translation_enabled = Rails.env.production? || ENV['ENABLE_AUTO_TRANSLATION'] == 'true'
```

## Implementation Details

### TranslationJob

The job uses proper Mobility patterns:

```ruby
class TranslationJob < ApplicationJob
  def perform(record_type, record_id, source_locale = 'en')
    record = record_type.constantize.find(record_id)

    # Get source text using Mobility
    source_text = nil
    Mobility.with_locale(source_locale.to_sym) do
      source_text = record.text
    end

    # Translate to each target locale
    target_locales.each do |target_locale|
      # Set translated text using Mobility
      Mobility.with_locale(target_locale) do
        record.text = translated_text
      end
    end

    # Save all translations
    record.save!
  end
end
```

### Model Callbacks

```ruby
class AssessmentQuestion < ApplicationRecord
  after_save :queue_translation_job, if: :should_auto_translate?

  private

  def queue_translation_job
    source_locale = default_locale || 'en'
    TranslationJob.perform_later(self.class.name, id, source_locale)
  end
end
```

## Usage Examples

### Creating Questions

```ruby
# Create a question - automatically queues translation job
question = AssessmentQuestions::MultipleChoice.create!(
  text: "What is your favorite programming language?",
  default_locale: "en",
  assessment: assessment,
  assessment_section: section
)
```

### Accessing Translations

```ruby
# Access translations using Mobility
Mobility.with_locale(:en) { question.text }  # English
Mobility.with_locale(:es) { question.text }  # Spanish
Mobility.with_locale(:ja) { question.text }  # Japanese
```

## Testing

```bash
# Test background translation jobs
rails test:background_translation

# Check translation status
rails test:check_translations[AssessmentQuestion,123]
```

## Supported Locales

- **English** (en) - Default
- **Spanish** (es)
- **Japanese** (ja)
- **Italian** (it)
- **French** (fr)

## Best Practices

1. **Set Default Locale**: Always specify source language
2. **Monitor Job Queue**: Track job success/failure rates
3. **Handle Failures**: Implement retry logic
4. **Test Thoroughly**: Verify translations are accurate
5. **Monitor Costs**: Google Translate API is pay-per-use
