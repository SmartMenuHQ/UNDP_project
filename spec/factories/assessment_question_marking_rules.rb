FactoryBot.define do
  factory :assessment_question_marking_rule do
    association :assessment_marking_scheme
    association :assessment_question
    rule_type { 'exact_match' }
    points { 10.0 }
    criteria { { expected_values: ['correct answer'] } }
    order { 1 }

    trait :option_based do
      rule_type { 'option_based' }
      criteria do
        {
          correct_options: [1, 2],
          partial_credit: false
        }
      end
    end

    trait :tolerance_based do
      rule_type { 'tolerance_based' }
      criteria do
        {
          expected_value: 42.0,
          tolerance: 2.0,
          tolerance_type: 'absolute'
        }
      end
    end

    trait :range_based do
      rule_type { 'range_based' }
      criteria do
        {
          min_value: 10,
          max_value: 50,
          include_boundaries: true
        }
      end
    end

    trait :keyword_based do
      rule_type { 'keyword_based' }
      criteria do
        {
          keywords: ['important', 'key', 'main'],
          case_sensitive: false,
          partial_credit: true,
          points_per_keyword: 2.0
        }
      end
    end

    trait :length_based do
      rule_type { 'length_based' }
      criteria do
        {
          min_length: 50,
          max_length: 200,
          points_per_word: 0.1
        }
      end
    end
  end
end
