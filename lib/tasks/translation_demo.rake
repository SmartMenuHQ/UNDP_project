namespace :translation do
  desc "Demo translation service functionality"
  task demo: :environment do
    puts "🌍 Translation Service Demo"
    puts "=" * 40

    # Check if Google API key is set
    unless ENV["GOOGLE_API_KEY"]
      puts "❌ Error: GOOGLE_API_KEY environment variable not set"
      puts "Please set your Google Translate API key:"
      puts "export GOOGLE_API_KEY=your_api_key_here"
      exit 1
    end

    # Create sample assessment
    assessment = Assessment.create!(
      title: "Sample Assessment",
      description: "A demo assessment to test translations"
    )

    section = assessment.assessment_sections.create!(
      name: "General Questions",
      order: 1
    )

    # Create questions
    multiple_choice = AssessmentQuestions::MultipleChoice.create!(
      text: "What is your favorite programming language?",
      assessment: assessment,
      assessment_section: section,
      order: 1,
      option_attributes: [
        { text: "Ruby", order: 1, assessment: assessment },
        { text: "Python", order: 2, assessment: assessment },
        { text: "JavaScript", order: 3, assessment: assessment }
      ]
    )

    radio = AssessmentQuestions::Radio.create!(
      text: "What is your experience level?",
      assessment: assessment,
      assessment_section: section,
      order: 2,
      option_attributes: [
        { text: "Beginner", order: 1, assessment: assessment },
        { text: "Intermediate", order: 2, assessment: assessment },
        { text: "Advanced", order: 3, assessment: assessment }
      ]
    )

    boolean = AssessmentQuestions::BooleanType.create!(
      text: "Do you enjoy coding?",
      assessment: assessment,
      assessment_section: section,
      order: 3
    )

    puts "✅ Created sample assessment with #{assessment.assessment_questions.count} questions"
    puts "   - Multiple choice: #{multiple_choice.option.count} options"
    puts "   - Radio: #{radio.option.count} options"
    puts "   - Boolean: #{boolean.option.count} options"
    puts

    # Initialize translation service
    translator = TranslationService.new

    puts "🔄 Starting translation process..."
    puts

    # Translate the entire assessment
    results = translator.translate_assessment(assessment)

    puts "📊 Translation Results:"
    puts "   Questions: #{results[:questions][:success]} success, #{results[:questions][:failed]} failed"
    puts "   Options: #{results[:options][:success]} success, #{results[:options][:failed]} failed"
    puts

    # Show translations for each question
    assessment.assessment_questions.each do |question|
      puts "❓ Question: #{question.text}"
      Rails.application.config.i18n.available_locales.each do |locale|
        next if locale == :en
        puts "   #{locale.upcase}: #{question.text(locale: locale)}"
      end
      puts

      if question.respond_to?(:option) && question.option.present?
        question.option.each do |option|
          puts "   📝 Option: #{option.text}"
          Rails.application.config.i18n.available_locales.each do |locale|
            next if locale == :en
            puts "      #{locale.upcase}: #{option.text(locale: locale)}"
          end
          puts
        end
      end
      puts "-" * 40
    end

    puts "🎉 Translation demo completed!"
  end

  desc "Translate a specific assessment by ID"
  task :translate_assessment, [:assessment_id] => :environment do |t, args|
    assessment_id = args[:assessment_id]

    unless assessment_id
      puts "❌ Error: Please provide an assessment ID"
      puts "Usage: rails translation:translate_assessment[123]"
      exit 1
    end

    assessment = Assessment.find(assessment_id)
    translator = TranslationService.new

    puts "🔄 Translating assessment: #{assessment.title}"
    results = translator.translate_assessment(assessment)

    puts "✅ Translation completed!"
    puts "Questions: #{results[:questions][:success]} success, #{results[:questions][:failed]} failed"
    puts "Options: #{results[:options][:success]} success, #{results[:options][:failed]} failed"
  end

  desc "Translate a specific question by ID"
  task :translate_question, [:question_id] => :environment do |t, args|
    question_id = args[:question_id]

    unless question_id
      puts "❌ Error: Please provide a question ID"
      puts "Usage: rails translation:translate_question[123]"
      exit 1
    end

    question = AssessmentQuestion.find(question_id)
    translator = TranslationService.new

    puts "🔄 Translating question: #{question.text}"
    results = translator.translate_question_with_options(question)

    puts "✅ Translation completed!"
    puts "Question: #{results[:question] ? 'Success' : 'Failed'}"
    puts "Options: #{results[:options].count { |o| o[:success] }} success, #{results[:options].count { |o| !o[:success] }} failed"
  end
end
