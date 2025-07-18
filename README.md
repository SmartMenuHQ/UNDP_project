# Questionnaire CMS

A comprehensive Content Management System for creating, managing, and previewing questionnaires with multiple question types, internationalization support, and modern UI.

## Features

- **Multiple Question Types**: Support for 7 different question types:
  - Multiple Choice
  - Radio Button
  - Boolean (Yes/No)
  - Date Picker
  - Number Range
  - Rich Text
  - File Upload

- **Dynamic Management**:
  - Add/edit/delete assessments, sections, and questions
  - Drag-and-drop ordering
  - Auto-naming for sections
  - Options management for choice-based questions

- **Internationalization**:
  - Built-in translation support using Mobility gem
  - Background translation jobs with Google Translate and DeepL
  - Support for multiple locales (EN, ES, FR, IT, JA)

- **Modern UI**:
  - Tailwind CSS for styling
  - Responsive design
  - Section-by-section preview with navigation
  - Real-time updates via AJAX

- **File Upload Configuration**:
  - Configurable file size limits
  - Allowed file type restrictions
  - Metadata storage for upload settings

## Requirements

- **Ruby**: 3.2.0
- **Rails**: 8.0.2
- **Database**: PostgreSQL 9.3+

## Installation

1. **Install rbenv (if not already installed)**

   **On macOS:**
   ```bash
   # Using Homebrew
   brew install rbenv ruby-build

   # Add rbenv to your shell profile
   echo 'eval "$(rbenv init -)"' >> ~/.zshrc
   source ~/.zshrc
   ```

   **On Linux:**
   ```bash
   # Install rbenv
   git clone https://github.com/rbenv/rbenv.git ~/.rbenv
   echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
   echo 'eval "$(rbenv init -)"' >> ~/.bashrc
   source ~/.bashrc

   # Install ruby-build
   git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
   ```

2. **Install the required Ruby version**
   ```bash
   rbenv install 3.2.0
   rbenv global 3.2.0
   # Verify installation
   ruby -v
   ```

3. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd questionnaire_cms
   ```

4. **Install Ruby dependencies**
   ```bash
   bundle install
   ```

5. **Setup the database**
   ```bash
   # Create and setup the database
   rails db:create
   rails db:migrate
   rails db:seed
   ```

## Running the Application

The application requires two processes to run simultaneously:

### Option 1: Using Two Terminal Windows (Recommended)

**Terminal 1 - Web Server:**
```bash
bin/rails server
```

**Terminal 2 - CSS Watcher:**
```bash
bin/rails tailwindcss:watch
```

### Option 2: Using Background Process

You can also run the CSS watcher in the background:
```bash
# Start CSS watcher in background
bin/rails tailwindcss:watch &

# Start web server in foreground
bin/rails server
```

This will start:
- **Web server**: Rails server on port 3000
- **CSS watcher**: Tailwind CSS compilation in watch mode

## Accessing the Application

- **Local Development**: http://localhost:3000
- **External Access**: The app is configured to accept any host in development mode, so you can use:
  - ngrok tunnels
  - IP addresses
  - Custom domains

## Usage

### Creating Your First Assessment

1. **Navigate to the homepage** - You'll see the assessments list
2. **Create a new assessment** - Click "New Assessment"
3. **Add sections** - Use the "Add Section" button (sections are auto-named)
4. **Add questions** - Use the dropdown to select question types
5. **Configure options** - For Multiple Choice/Radio questions, add and edit options
6. **Preview** - Use the "Preview" button to see your assessment section by section

### Managing Options

For Multiple Choice, Radio, and Boolean questions:
- **Add options**: Click the green "Add Option" button
- **Edit options**: Click directly in the text field and modify
- **Remove options**: Click the red trash icon
- **Reorder**: Options are automatically ordered

### Preview Mode

The preview shows:
- One section at a time
- Progress indicator
- Navigation between sections
- All question types rendered with proper inputs
- Section completion status

### Translation Features

The system supports automatic translation:
- Configure translation providers (Google Translate, DeepL)
- Enable auto-translation in `config/initializers/auto_translation.rb`
- Background jobs will translate content to configured locales

## Configuration

### Database Configuration

Edit `config/database.yml` if needed. Default development database:
```yaml
database: questionnaire_cms_development
```

### Translation Configuration

Edit `config/initializers/auto_translation.rb`:
```ruby
# Enable/disable auto-translation
Rails.application.config.auto_translation_enabled = true

# Configure available locales
Rails.application.config.i18n.available_locales = [:en, :es, :fr, :it, :ja]
```

### Host Configuration

For external access (ngrok, IP addresses), hosts are already configured in `config/environments/development.rb`:
```ruby
config.hosts.clear # Allows any host
```

## File Structure

```
questionnaire_cms/
├── app/
│   ├── controllers/assessments_controller.rb    # Main controller
│   ├── models/
│   │   ├── assessment.rb                        # Assessment model
│   │   ├── assessment_section.rb                # Section model
│   │   ├── assessment_question.rb               # Base question model
│   │   └── assessment_questions/                # Question type models
│   ├── views/assessments/                       # Assessment views
│   └── services/translation_service.rb          # Translation service
├── config/
│   ├── routes.rb                                # Application routes
│   └── initializers/auto_translation.rb         # Translation config
├── db/migrate/                                  # Database migrations
├── docs/                                        # Documentation
└── Procfile.dev                                 # Development processes
```

## Development

### Adding New Question Types

1. Create a new model in `app/models/assessment_questions/`
2. Add the question type to the dropdown in the edit view
3. Handle the question type in the preview view
4. Add any specific validations or associations

### Testing

Run the test suite:
```bash
rails test
```

### Background Jobs

The application uses background jobs for translation:
```bash
# Start the job queue (if needed)
rails jobs:work
```

## API Endpoints

The application provides AJAX endpoints for dynamic functionality:
- `POST /assessments/:id/add_section` - Add a new section
- `DELETE /assessments/:id/remove_section` - Remove a section
- `POST /assessments/:id/add_question` - Add a new question
- `DELETE /assessments/:id/remove_question` - Remove a question
- `PATCH /assessments/:id/update_question` - Update a question
- `POST /assessments/:id/add_option` - Add an option to a question
- `DELETE /assessments/:id/remove_option` - Remove an option
- `PATCH /assessments/:id/update_option` - Update an option

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.
