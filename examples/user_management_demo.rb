# User Management and Country Restrictions Demo
# Run this in Rails console: rails runner examples/user_management_demo.rb

puts "=== User Management & Country Restrictions Demo ==="

# Get our demo users
admin = User.find_by(email_address: "admin@questionnaire.com")
john = User.find_by(email_address: "john@example.com")  # USA
maria = User.find_by(email_address: "maria@example.com")  # Spain
yuki = User.find_by(email_address: "yuki@example.com")  # Japan

# Create a Chinese user to test restrictions
puts "\n👤 Creating Chinese user to test restrictions..."
china = Country.find_by(code: "CHN")
chinese_user = User.find_or_create_by(email_address: "li@example.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.admin = false
  user.first_name = "Li"
  user.last_name = "Wei"
  user.country = china
  user.default_language = "en"
  user.profile_completed = true
  user.invited_by = admin
  user.invited_at = 1.week.ago
  user.invitation_accepted_at = 1.day.ago
end

puts "✅ Created Chinese user: #{chinese_user.display_name} (#{chinese_user.country.name})"

assessment = Assessment.first
puts "\n📝 Testing with assessment: #{assessment.title}"

puts "\n=== User Profiles & Capabilities ==="
[admin, john, maria, yuki, chinese_user].each do |user|
  puts "\n👤 #{user.display_name}"
  puts "   Email: #{user.email_address}"
  puts "   Country: #{user.country&.display_name || 'Not set'}"
  puts "   Language: #{user.default_language}"
  puts "   Admin: #{user.admin? ? 'Yes' : 'No'}"
  puts "   Profile Complete: #{user.profile_completed? ? 'Yes' : 'No'} (#{user.profile_completion_percentage}%)"
  puts "   Can invite users: #{user.can_invite_users? ? 'Yes' : 'No'}"

  if user.invited_by
    puts "   Invited by: #{user.invited_by.display_name}"
    puts "   Invitation status: #{user.invitation_accepted? ? 'Accepted' : 'Pending'}"
  end
end

puts "\n=== Country Restrictions Testing ==="

# Test section restrictions
regional_section = assessment.assessment_sections.find_by(name: "Regional Technology Preferences")
puts "\n📂 Section: #{regional_section.name}"
puts "   Has restrictions: #{regional_section.has_country_restrictions?}"
puts "   Restricted countries: #{regional_section.restricted_country_names.join(', ')}"
puts "   Restriction description: #{regional_section.restriction_description}"

[john, maria, yuki, chinese_user].each do |user|
  accessible = regional_section.accessible_to_user?(user)
  puts "   • #{user.display_name} (#{user.country.code}): #{accessible ? '✅ Can access' : '❌ Restricted'}"
end

# Test question restrictions
social_media_question = assessment.assessment_questions.joins(:assessment_section)
                                   .find_by(assessment_sections: { name: "Regional Technology Preferences" })

puts "\n❓ Question: #{social_media_question.text['en'][0..50]}..."
puts "   Has restrictions: #{social_media_question.has_country_restrictions?}"
puts "   Restricted countries: #{social_media_question.restricted_country_names.join(', ')}"

[john, maria, yuki, chinese_user].each do |user|
  accessible = social_media_question.accessible_to_user?(user)
  puts "   • #{user.display_name} (#{user.country.code}): #{accessible ? '✅ Can access' : '❌ Restricted'}"
end

puts "\n=== Assessment Access Testing ==="

[john, maria, yuki, chinese_user].each do |user|
  puts "\n👤 #{user.display_name} (#{user.country.display_name}):"

  # Test assessment access
  can_take = user.can_access_content_with_restrictions?(assessment.restricted_countries || [])
  puts "   Can take assessment: #{can_take ? '✅ Yes' : '❌ No'}"

  # Count accessible sections
  accessible_sections = assessment.assessment_sections.select { |s| s.accessible_to_user?(user) }
  total_sections = assessment.assessment_sections.count
  puts "   Accessible sections: #{accessible_sections.count}/#{total_sections}"

  # Count accessible questions
  accessible_questions = assessment.assessment_questions.select { |q| q.accessible_to_user?(user) }
  total_questions = assessment.assessment_questions.count
  puts "   Accessible questions: #{accessible_questions.count}/#{total_questions}"

  # List restricted content
  restricted_sections = assessment.assessment_sections.reject { |s| s.accessible_to_user?(user) }
  restricted_questions = assessment.assessment_questions.reject { |q| q.accessible_to_user?(user) }

  if restricted_sections.any?
    puts "   ❌ Restricted sections: #{restricted_sections.map(&:name).join(', ')}"
  end

  if restricted_questions.any?
    puts "   ❌ Restricted questions: #{restricted_questions.count} questions"
  end
end

puts "\n=== Authorization Testing (Pundit Policies) ==="

# Test Assessment Policy
puts "\n📝 Assessment Policy Tests:"
[admin, john, chinese_user].each do |user|
  policy = AssessmentPolicy.new(user, assessment)

  puts "   #{user.display_name}:"
  puts "     • Can view assessments: #{policy.index? ? '✅' : '❌'}"
  puts "     • Can show this assessment: #{policy.show? ? '✅' : '❌'}"
  puts "     • Can create assessments: #{policy.create? ? '✅' : '❌'}"
  puts "     • Can edit assessments: #{policy.update? ? '✅' : '❌'}"
  puts "     • Can take assessment: #{policy.take_assessment? ? '✅' : '❌'}"
  puts "     • Can manage sections: #{policy.manage_sections? ? '✅' : '❌'}"
  puts "     • Can manage marking: #{policy.manage_marking? ? '✅' : '❌'}"
end

# Test User Policy
puts "\n👤 User Policy Tests:"
[admin, john].each do |current_user|
  puts "   #{current_user.display_name} acting on others:"

  [admin, john, chinese_user].each do |target_user|
    policy = UserPolicy.new(current_user, target_user)

    puts "     → #{target_user.display_name}:"
    puts "       • Can view: #{policy.show? ? '✅' : '❌'}"
    puts "       • Can edit: #{policy.update? ? '✅' : '❌'}"
    puts "       • Can delete: #{policy.destroy? ? '✅' : '❌'}"
    puts "       • Can make admin: #{policy.make_admin? ? '✅' : '❌'}"
    puts "       • Can invite: #{policy.invite? ? '✅' : '❌'}"
  end
end

# Test Country Policy
puts "\n🌍 Country Policy Tests:"
usa = Country.find_by(code: "USA")
[admin, john].each do |user|
  policy = CountryPolicy.new(user, usa)

  puts "   #{user.display_name}:"
  puts "     • Can view countries: #{policy.index? ? '✅' : '❌'}"
  puts "     • Can show country: #{policy.show? ? '✅' : '❌'}"
  puts "     • Can create countries: #{policy.create? ? '✅' : '❌'}"
  puts "     • Can edit countries: #{policy.update? ? '✅' : '❌'}"
  puts "     • Can delete countries: #{policy.destroy? ? '✅' : '❌'}"
  puts "     • Can manage restrictions: #{policy.manage_restrictions? ? '✅' : '❌'}"
end

puts "\n=== Invitation System Demo ==="

# Create a new user invitation
puts "\n📧 Testing user invitation system..."
new_user_email = "newuser@example.com"

# Admin invites a new user
if admin.can_invite_users?
  invited_user = User.new(
    email_address: new_user_email,
    password: "password123",
    password_confirmation: "password123"
  )

  if invited_user.save
    invited_user.invite!(admin)
    puts "✅ Admin invited new user: #{invited_user.email_address}"
    puts "   Invitation status: #{invited_user.pending_invitation? ? 'Pending' : 'Accepted'}"
    puts "   Invited by: #{invited_user.invited_by.display_name}"
    puts "   Invited at: #{invited_user.invited_at}"
  end
end

puts "\n=== Country Statistics ==="

Country.active.each do |country|
  user_count = country.users_count
  restricted_content = country.restricted_content_count

  puts "🏳️ #{country.flag_emoji} #{country.display_name}"
  puts "   Users: #{user_count}"
  puts "   Restricted questions: #{restricted_content[:questions]}"
  puts "   Restricted sections: #{restricted_content[:sections]}"
  puts "   Can be deleted: #{country.can_be_deleted? ? 'Yes' : 'No'}"
end

puts "\n=== Content Restriction Statistics ==="

question_stats = AssessmentQuestion.restriction_statistics
section_stats = AssessmentSection.restriction_statistics

puts "📊 Questions:"
puts "   Total: #{question_stats[:total]}"
puts "   With restrictions: #{question_stats[:with_restrictions]} (#{question_stats[:restriction_percentage]}%)"
puts "   Without restrictions: #{question_stats[:without_restrictions]}"

puts "📊 Sections:"
puts "   Total: #{section_stats[:total]}"
puts "   With restrictions: #{section_stats[:with_restrictions]} (#{section_stats[:restriction_percentage]}%)"
puts "   Without restrictions: #{section_stats[:without_restrictions]}"

# Show restricted content for China
puts "\n🇨🇳 Content restricted for China (CHN):"
restricted_questions = AssessmentQuestion.restricted_for_country_with_details("CHN")
restricted_sections = AssessmentSection.restricted_for_country_with_details("CHN")

puts "   Questions (#{restricted_questions.count}):"
restricted_questions.each do |item|
  puts "     • #{item[:title][0..60]}..."
end

puts "   Sections (#{restricted_sections.count}):"
restricted_sections.each do |item|
  puts "     • #{item[:title]}"
end

puts "\n=== Language Support Demo ==="

[john, maria, yuki, chinese_user].each do |user|
  puts "\n🌐 #{user.display_name} (#{user.country.display_name}):"
  puts "   Default language: #{user.default_language}"
  puts "   Available languages: #{user.available_languages.join(', ')}"

  # Show question text in user's language
  tech_question = assessment.assessment_questions.joins(:assessment_section)
                            .find_by(assessment_sections: { name: "Basic Information" })

  if tech_question&.text && tech_question.text[user.default_language]
    puts "   Sample question: #{tech_question.text[user.default_language]}"
  end
end

puts "\n🎉 Demo completed successfully!"
puts "\n💡 Key Features Demonstrated:"
puts "   ✅ User authentication with Rails 8 generator"
puts "   ✅ Role-based authorization with Pundit"
puts "   ✅ Country-based content restrictions"
puts "   ✅ Admin user invitation system"
puts "   ✅ Profile completion tracking"
puts "   ✅ Multi-language support"
puts "   ✅ Conditional content visibility"
puts "   ✅ Comprehensive policy-based permissions"

puts "\n🔧 Next Steps:"
puts "   • Implement REST API controllers"
puts "   • Add user profile completion flow"
puts "   • Create admin dashboard for user management"
puts "   • Build country restriction management interface"
puts "   • Add email notifications for invitations"
