# Translation Service Documentation

## Overview

The `TranslationService` is a Ruby service that integrates Google Translate API with the existing Mobility framework to automatically translate assessment questions and options into multiple languages.

## Features

- ✅ **Seamless Mobility Integration**: Works with the existing Mobility gem setup
- ✅ **Multi-language Support**: Supports English, Spanish, Japanese, Italian, and French
- ✅ **Batch Translation**: Translate entire assessments or multiple records at once
- ✅ **Smart Skipping**: Avoids re-translating existing translations
- ✅ **Error Handling**: Comprehensive error handling with detailed logging
- ✅ **Flexible API**: Multiple methods for different use cases

## Supported Locales

- **English** (en) - Default source language
- **Spanish** (es) - Español
- **Japanese** (ja) - 日本語
- **Italian** (it) - Italiano
- **French** (fr) - Français

## Prerequisites

### 1. Google Translate API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Translate API
4. Create credentials (API Key)
5. Set the environment variable:
   ```bash
   export GOOGLE_API_KEY=your_api_key_here
   ```

### 2. Install Dependencies

Add to your Gemfile:
```ruby
gem "google-cloud-translate", "~> 2.0"
```

Then run:
```bash
bundle install
```

## Usage

### Basic Usage

```ruby
# Initialize the service
translator = TranslationService.new

# Translate a single question
question = AssessmentQuestion.find(1)
translator.translate_record(question)

# Translate a question option
option = AssessmentQuestionOption.find(1)
translator.translate_record(option)
```

### Advanced Usage

```ruby
# Translate from specific source to specific target locales
translator.translate_record(question, :en, [:es, :fr])

# Translate an entire assessment
assessment = Assessment.find(1)
results = translator.translate_assessment(assessment)

# Translate a question with all its options
question = AssessmentQuestions::MultipleChoice.find(1)
results = translator.translate_question_with_options(question)

# Batch translate multiple records
questions = AssessmentQuestion.where(assessment_id: 1)
results = translator.translate_batch(questions)
```

## API Reference

### Methods

#### `translate_record(record, source_locale = :en, target_locales = nil)`
Translates a single record (question or option).

**Parameters:**
- `record`: AssessmentQuestion or AssessmentQuestionOption instance
- `source_locale`: Source language (default: :en)
- `target_locales`: Array of target locales (default: all available except source)

**Returns:** Boolean indicating success

#### `translate_assessment(assessment, source_locale = :en, target_locales = nil)`
Translates all questions and options in an assessment.

**Parameters:**
- `assessment`: Assessment instance
- `source_locale`: Source language (default: :en)
- `target_locales`: Array of target locales (default: all available except source)

**Returns:** Hash with success/failure counts for questions and options

#### `translate_question_with_options(question, source_locale = :en, target_locales = nil)`
Translates a question and all its options.

**Parameters:**
- `question`: AssessmentQuestion instance
- `source_locale`: Source language (default: :en)
- `target_locales`: Array of target locales (default: all available except source)

**Returns:** Hash with question result and array of option results

#### `translate_batch(records, source_locale = :en, target_locales = nil)`
Translates multiple records in batch.

**Parameters:**
- `records`: Array of AssessmentQuestion or AssessmentQuestionOption instances
- `source_locale`: Source language (default: :en)
- `target_locales`: Array of target locales (default: all available except source)

**Returns:** Hash with success/failure counts and error details

## Error Handling

The service includes comprehensive error handling:

```ruby
begin
  translator.translate_record(question)
rescue TranslationService::TranslationError => e
  puts "Translation failed: #{e.message}"
end
```

## Rake Tasks

### Demo Task
Run a complete demo with sample data:
```bash
rails translation:demo
```

### Translate Assessment
Translate a specific assessment:
```bash
rails translation:translate_assessment[123]
```

### Translate Question
Translate a specific question:
```bash
rails translation:translate_question[456]
```

## Integration Examples

### In Controllers

```ruby
class QuestionsController < ApplicationController
  def translate
    @question = AssessmentQuestion.find(params[:id])
    translator = TranslationService.new

    if translator.translate_record(@question)
      redirect_to @question, notice: 'Question translated successfully!'
    else
      redirect_to @question, alert: 'Translation failed.'
    end
  end
end
```

### In Background Jobs

```ruby
class TranslationJob < ApplicationJob
  queue_as :default

  def perform(assessment_id)
    assessment = Assessment.find(assessment_id)
    translator = TranslationService.new

    results = translator.translate_assessment(assessment)
    Rails.logger.info "Translation completed: #{results}"
  end
end
```

### In Rails Console

```ruby
# Check available translations
question = AssessmentQuestion.find(1)
puts "English: #{question.text(locale: :en)}"
puts "Spanish: #{question.text(locale: :es)}"
puts "Japanese: #{question.text(locale: :ja)}"
puts "Italian: #{question.text(locale: :it)}"
puts "French: #{question.text(locale: :fr)}"
```

## Best Practices

1. **API Key Security**: Never commit API keys to version control
2. **Rate Limiting**: Be mindful of Google Translate API rate limits
3. **Batch Processing**: Use batch methods for large datasets
4. **Error Handling**: Always handle TranslationError exceptions
5. **Logging**: Monitor translation success/failure rates
6. **Cost Management**: Google Translate API has usage-based pricing

## Troubleshooting

### Common Issues

1. **API Key Not Set**
   ```
   Error: GOOGLE_API_KEY environment variable not set
   ```
   Solution: Set the environment variable with your API key

2. **Translation Failed**
   ```
   Google Translate API error: [error message]
   ```
   Solution: Check API key, network connectivity, and API quotas

3. **Record Not Found**
   ```
   Record must respond to text
   ```
   Solution: Ensure you're passing AssessmentQuestion or AssessmentQuestionOption instances

### Debug Mode

Enable debug logging:
```ruby
Rails.logger.level = Logger::DEBUG
```

## Performance Considerations

- The service skips existing translations to avoid unnecessary API calls
- Use batch methods for translating multiple records
- Consider using background jobs for large translation tasks
- Monitor Google Translate API usage and costs

## Contributing

When adding new locales:
1. Add the locale to `config/application.rb`
2. Create the locale file in `config/locales/`
3. Update the `normalize_locale` method in `TranslationService`

## License

This service is part of the Questionnaire CMS project.
