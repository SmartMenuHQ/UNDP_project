#!/usr/bin/env ruby
# Test script for section auto-naming

require_relative 'config/environment'

puts "=== Testing Section Auto-Naming ==="
puts

# Clean up any existing test data
Assessment.where(title: "Test Assessment for Auto-Naming").destroy_all

# Create a test assessment
assessment = Assessment.create!(
  title: "Test Assessment for Auto-Naming",
  description: "Testing auto-naming functionality"
)

puts "Created assessment: #{assessment.title}"
puts "Assessment ID: #{assessment.id}"
puts

# Test 1: Create first section (should be "Section 1")
puts "Test 1: Creating first section"
section1 = assessment.assessment_sections.build
puts "Before save - Name: '#{section1.name}', Order: #{section1.order}"
puts "Validation errors before save: #{section1.errors.full_messages}" unless section1.valid?

if section1.save
  puts "After save - Name: '#{section1.name}', Order: #{section1.order}"
  puts "✅ First section created successfully"
else
  puts "❌ First section failed to save: #{section1.errors.full_messages.join(', ')}"
end
puts

# Test 2: Create second section (should be "Section 2")
puts "Test 2: Creating second section"
section2 = assessment.assessment_sections.build
puts "Before save - Name: '#{section2.name}', Order: #{section2.order}"

if section2.save
  puts "After save - Name: '#{section2.name}', Order: #{section2.order}"
  puts "✅ Second section created successfully"
else
  puts "❌ Second section failed to save: #{section2.errors.full_messages.join(', ')}"
end
puts

# Test 3: Create section with explicit name (should keep the name)
puts "Test 3: Creating section with explicit name"
section3 = assessment.assessment_sections.build(name: "Custom Section Name")
puts "Before save - Name: '#{section3.name}', Order: #{section3.order}"

if section3.save
  puts "After save - Name: '#{section3.name}', Order: #{section3.order}"
  puts "✅ Custom named section created successfully"
else
  puts "❌ Custom named section failed to save: #{section3.errors.full_messages.join(', ')}"
end
puts

# Show all sections
puts "All sections for this assessment:"
assessment.assessment_sections.ordered.each do |section|
  puts "  - #{section.name} (Order: #{section.order})"
end
puts

# Clean up
puts "Cleaning up test data..."
assessment.destroy
puts "✅ Test completed!"
