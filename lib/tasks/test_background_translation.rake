namespace :test do
  desc "Test background translation jobs"
  task background_translation: :environment do
    puts "🧪 Testing Background Translation Jobs"
    puts "=" * 50

    # Check configuration
    current_provider = ENV.fetch('TRANSLATION_PROVIDER', 'google')
    puts "Configuration:"
    puts "  Auto-translation enabled: #{Rails.application.config.auto_translation_enabled}"
    puts "  Translation provider: #{current_provider}"
    puts "  Available locales: #{Rails.application.config.i18n.available_locales.join(', ')}"
    puts "  Background job adapter: #{Rails.application.config.active_job.queue_adapter}"
    puts

    unless Rails.application.config.auto_translation_enabled
      puts "❌ Auto-translation is disabled"
      puts "To enable: export ENABLE_AUTO_TRANSLATION=true"
      exit 1
    end

    # Check provider configuration
    provider_key = current_provider == 'google' ? 'GOOGLE_API_KEY' : 'DEEPL_AUTH_KEY'
    unless ENV[provider_key]
      puts "❌ #{provider_key} not set for #{current_provider} provider"
      puts "Please set your API key:"
      if current_provider == 'google'
        puts "  export GOOGLE_API_KEY=your_google_key"
      else
        puts "  export DEEPL_AUTH_KEY=your_deepl_key"
      end
      exit 1
    end

    puts "✅ #{current_provider.capitalize} provider configured"

    # Create test assessment
    assessment = Assessment.create!(
      title: "Background Translation Test (#{current_provider})",
      description: "Testing automatic translation with background jobs using #{current_provider}"
    )

    section = assessment.assessment_sections.create!(
      name: "Test Section",
      order: 1
    )

    puts "✅ Created test assessment and section"

    # Test 1: Create multiple choice question - should queue translation job
    puts "\n📝 Test 1: Multiple Choice Question (should queue job)"
    mc_question = AssessmentQuestions::MultipleChoice.create!(
      text: "What is your favorite programming language?",
      default_locale: "en",
      assessment: assessment,
      assessment_section: section,
      order: 1
    )

    puts "✅ Created question: #{mc_question.text}"
    puts "📄 Check logs for: 'Queued translation job for AssessmentQuestion'"

    # Test 2: Add options - should queue translation jobs
    puts "\n📝 Test 2: Adding Options (should queue jobs)"
    ["Ruby", "Python", "JavaScript"].each_with_index do |option_text, index|
      option = mc_question.option.create!(
        text: option_text,
        default_locale: "en",
        order: index + 1,
        assessment: assessment
      )
      puts "✅ Created option: #{option.text}"
    end
    puts "📄 Check logs for: 'Queued translation job for AssessmentQuestionOption'"

    # Test 3: Boolean question - should queue job and create options
    puts "\n📝 Test 3: Boolean Question (should queue job and create options)"
    boolean_question = AssessmentQuestions::BooleanType.create!(
      text: "Do you enjoy coding?",
      default_locale: "en",
      assessment: assessment,
      assessment_section: section,
      order: 2
    )

    puts "✅ Created boolean question: #{boolean_question.text}"
    puts "✅ Created #{boolean_question.option.count} boolean options"
    boolean_question.option.each do |option|
      puts "  - #{option.text} (order: #{option.order})"
    end

    # Test 4: Question with different default locale
    puts "\n📝 Test 4: Spanish Question (should queue job)"
    spanish_question = AssessmentQuestions::Radio.create!(
      text: "¿Cuál es tu experiencia con programación?",
      default_locale: "es",
      assessment: assessment,
      assessment_section: section,
      order: 3
    )

    puts "✅ Created Spanish question: #{spanish_question.text}"

    # Test 5: Manual job execution
    puts "\n📝 Test 5: Manual Job Execution with #{current_provider.capitalize}"
    puts "Executing translation job manually for the first question..."

    begin
      TranslationJob.perform_now("AssessmentQuestion", mc_question.id, "en")
      puts "✅ Job executed successfully"

      # Check translations
      puts "Translations using #{current_provider}:"
      Rails.application.config.i18n.available_locales.each do |locale|
        Mobility.with_locale(locale) do
          translation = mc_question.text
          puts "  #{locale.upcase}: #{translation.present? ? translation : 'Not translated'}"
        end
      end
    rescue StandardError => e
      puts "❌ Job failed: #{e.message}"
    end

    puts "\n📊 Job Queue Status:"
    if defined?(Sidekiq)
      puts "  Sidekiq queue size: #{Sidekiq::Queue.new.size}"
    else
      puts "  Using Rails built-in job queue"
    end

    puts "\n🎯 Next Steps:"
    puts "1. Check the logs for job execution"
    puts "2. Wait for jobs to process (if using async queue)"
    puts "3. Run rails console to check translations:"
    puts "   question = AssessmentQuestion.find(#{mc_question.id})"
    puts "   Mobility.with_locale(:es) { question.text }"
    puts "   Mobility.with_locale(:ja) { question.text }"
    puts "4. Compare with different provider:"
    puts "   TRANSLATION_PROVIDER=#{current_provider == 'google' ? 'deepl' : 'google'} rails test:background_translation"
    puts "5. Clean up test data: rails test:clean_translation_test"

    puts "\n🎉 Background translation job test completed with #{current_provider.capitalize}!"
  end

  desc "Check translation status for a record"
  task :check_translations, [:model, :id] => :environment do |t, args|
    model = args[:model]
    id = args[:id]

    unless model && id
      puts "❌ Usage: rails test:check_translations[AssessmentQuestion,123]"
      exit 1
    end

    record = model.constantize.find(id)
    current_provider = ENV.fetch('TRANSLATION_PROVIDER', 'google')

    puts "🔍 Translation status for #{model} ##{id}:"
    puts "Provider used: #{current_provider}"
    puts "Text: #{record.text}"
    puts

    Rails.application.config.i18n.available_locales.each do |locale|
      Mobility.with_locale(locale) do
        translation = record.text
        status = translation.present? ? "✅" : "❌"
        puts "#{status} #{locale.upcase}: #{translation || 'Not translated'}"
      end
    end
  end

  desc "Process pending translation jobs"
  task process_translation_jobs: :environment do
    current_provider = ENV.fetch('TRANSLATION_PROVIDER', 'google')
    puts "🔄 Processing pending translation jobs with #{current_provider.capitalize}..."

    # This will depend on your job queue adapter
    if Rails.application.config.active_job.queue_adapter == :sidekiq
      puts "Using Sidekiq - jobs will be processed by Sidekiq workers"
    else
      puts "Using Rails built-in adapter - processing jobs now..."
      # For development, you might need to manually process jobs
      # This is adapter-specific
    end

    puts "Check your job queue system for processing status"
  end
end
