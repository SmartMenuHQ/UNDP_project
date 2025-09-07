FactoryBot.define do
  factory :assessment_marking_scheme do
    association :assessment
    name { Faker::Lorem.words(number: 2).join(' ').titleize }
    description { Faker::Lorem.sentence }
    is_active { false }
    settings { {} }
    total_possible_score { 100.0 }
    passing_score { 60.0 }

    trait :active do
      is_active { true }
    end

    trait :with_grade_boundaries do
      settings do
        {
          'grade_boundaries' => {
            'A' => 90,
            'B' => 80,
            'C' => 70,
            'D' => 60,
            'F' => 0
          }
        }
      end
    end

    trait :with_feedback_templates do
      settings do
        {
          'feedback_templates' => {
            'A' => 'Excellent work %{name}! You scored %{score}/%{max_score} (%{percentage}%)',
            'B' => 'Good job %{name}! You scored %{score}/%{max_score} (%{percentage}%)',
            'C' => 'Fair work %{name}. You scored %{score}/%{max_score} (%{percentage}%)',
            'D' => 'You passed %{name}, but consider reviewing the material. Score: %{score}/%{max_score} (%{percentage}%)',
            'F' => 'Unfortunately %{name}, you did not pass. Score: %{score}/%{max_score} (%{percentage}%)'
          }
        }
      end
    end

    trait :complete do
      with_grade_boundaries
      with_feedback_templates
    end
  end
end
