# File Upload Configuration (with store_accessor and validations)

The `AssessmentQuestions::FileUpload` class now supports configuring allowed data types and maximum file size through the `meta_data` JSONB column using Rails' `store_accessor` feature, with built-in validations for data integrity.

## Features

- **Store Accessor Integration**: Clean attribute access using Rails' `store_accessor`
- **Built-in Validations**: Comprehensive validation for configuration integrity
- **Configurable Data Types**: Set which MIME types are allowed for file uploads
- **Configurable Max File Size**: Set maximum file size limit in bytes
- **Validation Methods**: Built-in validation for file type and size
- **Preset Configurations**: Quick setup for common use cases
- **Human-Readable Display**: Helper methods for displaying file constraints
- **Type Coercion**: Automatic type conversion in setters

## Store Accessor Implementation

The model uses Rails' `store_accessor` to provide clean attribute access:

```ruby
class FileUpload < AssessmentQuestion
  store_accessor :meta_data, :allowed_data_types, :max_file_size

  # Direct attribute access (no manual JSON parsing needed)
  validates :allowed_data_types, presence: true
  validates :max_file_size, presence: true, numericality: { greater_than: 0 }
  validate :validate_allowed_data_types_format
  validate :validate_max_file_size_reasonable
end
```

## Configuration Methods

### Setting Allowed Data Types

```ruby
file_question = AssessmentQuestions::FileUpload.create!(
  text: "Please upload a file",
  assessment: assessment,
  assessment_section: section,
  order: 1
)

# Set allowed data types (array)
file_question.allowed_data_types = ['image/jpeg', 'image/png', 'application/pdf']

# Or set single type (automatically converted to array)
file_question.allowed_data_types = 'image/jpeg'

file_question.save!
```

### Setting Maximum File Size

```ruby
# Set max file size (automatically converted to integer)
file_question.max_file_size = 5.megabytes
file_question.save!

# Or use other units
file_question.max_file_size = 500.kilobytes
file_question.max_file_size = 1.gigabyte
```

### Using Preset Configurations

```ruby
# Configure for images only (JPEG, PNG, GIF - 5MB max)
file_question.configure_for_images_only

# Configure for documents only (PDF, DOC, DOCX - 20MB max)
file_question.configure_for_documents_only

# Configure for all supported types (10MB max)
file_question.configure_for_all_types
```

## Validations

### Built-in Model Validations

The model includes comprehensive validations:

```ruby
# Check if configuration is valid
file_question.valid?

# Get validation errors
file_question.errors.full_messages
```

**Validation Rules:**

1. **Presence**: Both `allowed_data_types` and `max_file_size` are required
2. **Data Types Format**: Must be an array of valid MIME types (containing '/')
3. **Data Types Count**: Must contain at least one file type
4. **File Size Range**: Must be between 1KB and 100MB
5. **File Size Numeric**: Must be a positive number

### Validation Examples

```ruby
# Valid configuration
file_question.allowed_data_types = ['image/jpeg', 'image/png']
file_question.max_file_size = 5.megabytes
file_question.valid? # => true

# Invalid: empty array
file_question.allowed_data_types = []
file_question.valid? # => false
file_question.errors.full_messages # => ["Allowed data types must contain at least one file type"]

# Invalid: bad MIME type
file_question.allowed_data_types = ['invalid-type']
file_question.valid? # => false
file_question.errors.full_messages # => ["Allowed data types contains invalid MIME type: invalid-type"]

# Invalid: file size too small
file_question.max_file_size = 500 # 500 bytes
file_question.valid? # => false
file_question.errors.full_messages # => ["Max file size must be at least 1KB"]

# Invalid: file size too large
file_question.max_file_size = 200.megabytes
file_question.valid? # => false
file_question.errors.full_messages # => ["Max file size cannot exceed 100MB"]
```

## Default Configuration

Default values are set automatically via `after_initialize` callback:

- **Default Allowed Types**:
  - `image/jpeg`
  - `image/png`
  - `image/gif`
  - `application/pdf`
  - `application/msword`
  - `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
  - `text/plain`

- **Default Max File Size**: 10MB

## File Upload Validation

### Individual Validation Methods

```ruby
# Validate file type
is_valid_type = file_question.validate_file_type(uploaded_file)

# Validate file size
is_valid_size = file_question.validate_file_size(uploaded_file)
```

### Comprehensive Validation

```ruby
# Get all validation errors for a file
errors = file_question.validate_uploaded_file(uploaded_file)

if errors.any?
  # Handle validation errors
  flash[:error] = errors.join(', ')
  redirect_back(fallback_location: root_path)
  return
end
```

## Display Helpers

### Human-Readable File Size

```ruby
file_question.max_file_size_human
# Returns: "5MB", "500KB", or "1024 bytes"
```

### Allowed Extensions

```ruby
file_question.allowed_extensions
# Returns: ".jpg, .jpeg, .png, .pdf, .doc, .docx, .txt"
```

## Available File Type Presets

Access predefined file type collections:

```ruby
AssessmentQuestions::FileUpload.common_file_types
# Returns:
# {
#   images: ['image/jpeg', 'image/png', 'image/gif'],
#   documents: ['application/pdf', 'application/msword', ...],
#   text: ['text/plain'],
#   all: [...] # All supported types
# }
```

## Usage in Controllers

### File Upload Validation with Error Handling

```ruby
class AssessmentResponsesController < ApplicationController
  def create
    @question = AssessmentQuestion.find(params[:question_id])
    uploaded_file = params[:uploaded_file]

    if uploaded_file.present? && @question.is_a?(AssessmentQuestions::FileUpload)
      # First check if question configuration is valid
      unless @question.valid?
        flash[:error] = "File upload configuration error: #{@question.errors.full_messages.join(', ')}"
        redirect_back(fallback_location: assessment_path(@question.assessment))
        return
      end

      # Then validate the uploaded file
      validation_errors = @question.validate_uploaded_file(uploaded_file)

      if validation_errors.any?
        flash[:error] = validation_errors.join(', ')
        redirect_back(fallback_location: assessment_path(@question.assessment))
        return
      end
    end

    # Process the valid file upload
    # ...
  end
end
```

### Display File Constraints

```ruby
# In your view
<%= form_with model: @response do |form| %>
  <% if @question.is_a?(AssessmentQuestions::FileUpload) %>
    <div class="file-constraints">
      <p><strong>Max file size:</strong> <%= @question.max_file_size_human %></p>
      <p><strong>Allowed file types:</strong> <%= @question.allowed_extensions %></p>
    </div>
  <% end %>

  <%= form.file_field :uploaded_file,
                      accept: @question.allowed_data_types.join(','),
                      data: { max_size: @question.max_file_size } %>
<% end %>
```

## Store Accessor Benefits

### Direct Attribute Access

```ruby
# No manual JSON parsing needed
file_question.allowed_data_types # Direct array access
file_question.max_file_size       # Direct integer access

# Clean assignment
file_question.allowed_data_types = ['image/jpeg']
file_question.max_file_size = 5.megabytes
```

### Form Integration

```ruby
# Works seamlessly with Rails forms
<%= form_with model: @file_question do |form| %>
  <%= form.collection_check_boxes :allowed_data_types,
                                   available_mime_types,
                                   :first, :last %>
  <%= form.number_field :max_file_size %>
<% end %>
```

## Meta Data Storage

The configuration is stored in the `meta_data` JSONB column:

```ruby
file_question.meta_data
# Returns:
# {
#   "allowed_data_types" => ["image/jpeg", "image/png"],
#   "max_file_size" => 5242880
# }

# Direct access via store_accessor
file_question.allowed_data_types # => ["image/jpeg", "image/png"]
file_question.max_file_size      # => 5242880
```

## Testing

Run the comprehensive test suite:

```bash
# Test all file upload configuration features
rails file_upload:test_configuration

# Test validations specifically
rails file_upload:test_validations

# Show usage examples
rails file_upload:usage_examples
```

## Common Use Cases

### Profile Picture Upload

```ruby
profile_pic_question.configure_for_images_only
profile_pic_question.max_file_size = 2.megabytes
profile_pic_question.save!

# Validation will ensure configuration is valid
profile_pic_question.valid? # => true
```

### Document Submission

```ruby
document_question.configure_for_documents_only
document_question.max_file_size = 50.megabytes
document_question.save!

# Check validation
if document_question.valid?
  # Configuration is valid
else
  # Handle validation errors
  puts document_question.errors.full_messages
end
```

### Custom Configuration with Validation

```ruby
resume_question.allowed_data_types = ['application/pdf', 'application/msword']
resume_question.max_file_size = 10.megabytes

# Validate before saving
if resume_question.valid?
  resume_question.save!
else
  # Handle validation errors
  resume_question.errors.full_messages.each do |error|
    puts "Error: #{error}"
  end
end
```

## Error Handling

### Model Validation Errors

```ruby
# Configuration validation errors:
# "Allowed data types can't be blank"
# "Max file size can't be blank"
# "Max file size must be greater than 0"
# "Allowed data types must contain at least one file type"
# "Allowed data types contains invalid MIME type: invalid-type"
# "Max file size must be at least 1KB"
# "Max file size cannot exceed 100MB"
```

### File Upload Validation Errors

```ruby
# File validation errors:
# "File type 'text/plain' is not allowed. Allowed types: image/jpeg, image/png, application/pdf"
# "File size 15728640 bytes exceeds maximum allowed size of 5242880 bytes (5MB)"
```

## Integration with Active Storage

This configuration works seamlessly with Rails Active Storage:

```ruby
class Assessment < ApplicationRecord
  has_one_attached :uploaded_file

  validate :validate_uploaded_file_constraints

  private

  def validate_uploaded_file_constraints
    return unless uploaded_file.attached?

    file_question = # ... get the associated file upload question

    # Ensure question configuration is valid
    unless file_question.valid?
      errors.add(:uploaded_file, "Configuration error: #{file_question.errors.full_messages.join(', ')}")
      return
    end

    # Validate the uploaded file
    validation_errors = file_question.validate_uploaded_file(uploaded_file)
    validation_errors.each { |error| errors.add(:uploaded_file, error) }
  end
end
```

## Migration Considerations

When upgrading existing FileUpload questions, the `after_initialize` callback will automatically set default values for any existing records that don't have configuration set in their `meta_data` column.

## Best Practices

1. **Always validate configuration** before saving
2. **Use preset configurations** for common use cases
3. **Set reasonable file size limits** based on your server capacity
4. **Provide clear error messages** to users
5. **Test file upload validation** thoroughly
6. **Consider storage costs** when setting file size limits
