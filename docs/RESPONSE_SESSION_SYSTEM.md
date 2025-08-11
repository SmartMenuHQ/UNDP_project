# Response Session System Documentation

## Overview

The Response Session System provides comprehensive state management for assessment attempts using AASM (Acts As State Machine). It tracks the complete lifecycle of a respondent's interaction with an assessment, from initial draft through completion, submission, marking, and result publication.

## Architecture

### Core Model: AssessmentResponseSession

The `AssessmentResponseSession` model is the central component that manages:

- **Respondent Information** - Name, email, and metadata
- **State Management** - 10 distinct states with controlled transitions
- **Progress Tracking** - Completion percentage, duration, timestamps
- **Score Management** - Integration with the marking system
- **Analytics** - Statistics and reporting capabilities

### Database Schema

```sql
CREATE TABLE assessment_response_sessions (
  id                   BIGINT PRIMARY KEY,
  assessment_id        BIGINT NOT NULL REFERENCES assessments(id),
  respondent_name      VARCHAR NOT NULL,
  respondent_email     VARCHAR,
  state                VARCHAR NOT NULL DEFAULT 'draft',
  started_at           TIMESTAMP,
  completed_at         TIMESTAMP,
  submitted_at         TIMESTAMP,
  marked_at            TIMESTAMP,
  total_score          DECIMAL(10,2) DEFAULT 0.0,
  max_possible_score   DECIMAL(10,2) DEFAULT 0.0,
  grade                VARCHAR,
  feedback             TEXT,
  metadata             JSONB DEFAULT '{}',
  created_at           TIMESTAMP NOT NULL,
  updated_at           TIMESTAMP NOT NULL
);
```

### Associations

```ruby
# AssessmentResponseSession
belongs_to :assessment
has_many :assessment_question_responses, dependent: :destroy
has_many :assessment_response_scores, through: :assessment_question_responses

# Assessment
has_many :assessment_response_sessions, dependent: :destroy

# AssessmentQuestionResponse
belongs_to :assessment_response_session, optional: true
```

## State Machine (AASM)

### States

1. **draft** (initial) - Session created but not started
2. **started** - Session initiated, timer started
3. **in_progress** - Respondent actively answering questions
4. **completed** - All required questions answered
5. **submitted** - Responses submitted for review
6. **under_review** - Manual review in progress
7. **marked** - Automatically graded with scores calculated
8. **published** - Results made available to respondent
9. **cancelled** - Session cancelled before completion
10. **expired** - Session timed out or expired

### State Transitions

```ruby
# Available transitions
draft → started → in_progress → completed → submitted → under_review → marked → published
  ↓         ↓           ↓            ↓
cancelled cancelled  cancelled   expired
  ↓         ↓           ↓            ↓
in_progress ← reopen ← reopen ← reopen
```

### Transition Events

```ruby
# Start assessment
session.start!              # draft → started

# Begin answering
session.begin_answering!    # draft/started → in_progress

# Complete assessment (requires all required questions answered)
session.complete!           # started/in_progress → completed

# Submit for grading
session.submit!             # completed → submitted

# Send for manual review
session.send_for_review!    # submitted → under_review

# Automatically mark/grade
session.mark!               # submitted/under_review → marked

# Publish results
session.publish_results!    # marked → published

# Administrative actions
session.cancel!             # draft/started/in_progress → cancelled
session.expire!             # draft/started/in_progress/completed → expired
session.reopen!             # cancelled/expired → in_progress
session.reset!              # any state → draft (clears all data)
```

## Key Features

### 1. Progress Tracking

```ruby
session = AssessmentResponseSession.find(id)

# Duration tracking
session.duration                    # Total seconds
session.duration_formatted          # "1h 23m 45s"

# Completion tracking
session.completion_percentage       # 75.5%
session.can_be_completed?          # true/false

# State checks
session.draft?                     # true/false
session.completed?                 # true/false
session.marked?                    # true/false
```

### 2. Response Management

```ruby
# Create responses for questions
session.create_response_for_question(question, value)

# Get response for specific question
response = session.responses_for_question(question)

# Check if all required questions answered
session.all_required_questions_answered?
```

### 3. Automatic Scoring Integration

```ruby
# Automatic scoring when marked
session.mark!  # Triggers calculate_final_score! and generate_feedback!

# Score information
session.total_score                 # 85.5
session.max_possible_score         # 100.0
session.score_percentage           # 85.5%
session.grade                      # "B"
session.passed?                    # true/false
```

### 4. Analytics and Statistics

```ruby
# Assessment-level statistics
stats = AssessmentResponseSession.stats_for_assessment(assessment)
# Returns:
{
  total: 150,
  by_state: { "completed" => 120, "in_progress" => 20, "draft" => 10 },
  average_score: 78.5,
  pass_rate: 82.5,
  average_duration: "45m"
}

# Individual session analytics
session.duration_formatted          # "1h 23m"
session.completion_percentage       # 95.0%
session.score_percentage           # 87.5%
```

## Controller Integration

### ResponseSessionsController

Provides full CRUD operations plus state management:

```ruby
# Standard CRUD
GET    /assessments/:assessment_id/responses           # index
GET    /assessments/:assessment_id/responses/new       # new
POST   /assessments/:assessment_id/responses           # create
GET    /assessments/:assessment_id/responses/:id       # show
GET    /assessments/:assessment_id/responses/:id/edit  # edit
PATCH  /assessments/:assessment_id/responses/:id       # update
DELETE /assessments/:assessment_id/responses/:id       # destroy

# State transitions
PATCH  /assessments/:assessment_id/responses/:id/start    # start session
PATCH  /assessments/:assessment_id/responses/:id/submit   # submit for grading
PATCH  /assessments/:assessment_id/responses/:id/mark     # mark/grade
PATCH  /assessments/:assessment_id/responses/:id/publish  # publish results
PATCH  /assessments/:assessment_id/responses/:id/cancel   # cancel session
PATCH  /assessments/:assessment_id/responses/:id/reset    # reset session

# Bulk operations
POST   /assessments/:assessment_id/responses/bulk_mark    # mark multiple
POST   /assessments/:assessment_id/responses/bulk_publish # publish multiple

# Analytics and reporting
GET    /assessments/:assessment_id/responses/analytics    # analytics dashboard
GET    /assessments/:assessment_id/responses/export       # CSV/JSON export
```

## Usage Examples

### 1. Creating a Response Session

```ruby
# For anonymous respondent
session = AssessmentResponseSession.create!(
  assessment: assessment,
  respondent_name: "Anonymous User",
  metadata: {
    browser_info: "Chrome 120.0",
    ip_address: "192.168.1.100"
  }
)

# For registered respondent
session = AssessmentResponseSession.create_for_respondent(
  "John Doe",
  "john@example.com",
  assessment,
  { source: "email_invitation" }
)
```

### 2. Managing Session Lifecycle

```ruby
# Start assessment
session.start! if session.may_start?

# Record responses
question = assessment.assessment_questions.first
session.create_response_for_question(question, { "text" => "My answer" })

# Complete when ready
if session.can_be_completed?
  session.complete!
  session.submit!
end

# Automatic marking
if session.can_be_marked?
  session.mark!  # Calculates scores and generates feedback
end

# Publish results
session.publish_results! if session.may_publish_results?
```

### 3. Querying and Filtering

```ruby
# Get sessions by state
submitted_sessions = assessment.assessment_response_sessions.by_state('submitted')

# Get recent sessions
recent = assessment.assessment_response_sessions.recent.limit(10)

# Get sessions within date range
this_month = assessment.assessment_response_sessions
                      .completed_between(1.month.ago, Date.current)

# Get sessions with/without email
registered = assessment.assessment_response_sessions.with_email
anonymous = assessment.assessment_response_sessions.anonymous
```

### 4. Bulk Operations

```ruby
# Mark multiple sessions
sessions_to_mark = assessment.assessment_response_sessions
                            .where(state: 'submitted')

sessions_to_mark.each do |session|
  session.mark! if session.may_mark?
end

# Publish all marked sessions
marked_sessions = assessment.assessment_response_sessions
                           .where(state: 'marked')

marked_sessions.each(&:publish_results!)
```

## Validation and Error Handling

### Built-in Validations

```ruby
validates :respondent_name, presence: true, length: { minimum: 2, maximum: 100 }
validates :respondent_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
validates :respondent_email, uniqueness: { scope: :assessment_id }, allow_blank: true
validates :total_score, :max_possible_score, numericality: { greater_than_or_equal_to: 0 }
```

### State Transition Guards

```ruby
# Can only complete if all required questions answered
event :complete do
  transitions from: [:started, :in_progress], to: :completed,
              guard: :all_required_questions_answered?
end

# Can only mark if submitted and marking scheme exists
def can_be_marked?
  submitted? && assessment.assessment_marking_schemes.active.exists?
end
```

### Error Handling

```ruby
begin
  session.mark!
rescue AASM::InvalidTransition => e
  # Handle invalid state transition
  Rails.logger.error "Cannot mark session #{session.id}: #{e.message}"
rescue => e
  # Handle other errors (scoring, database, etc.)
  Rails.logger.error "Error marking session #{session.id}: #{e.message}"
end
```

## Metadata and Customization

### Metadata Storage

The `metadata` JSONB field supports flexible data storage:

```ruby
session.metadata = {
  browser_info: "Chrome 120.0.6099.109",
  ip_address: "192.168.1.100",
  screen_resolution: "1920x1080",
  time_zone: "America/New_York",
  referrer: "https://example.com/assessments",
  session_id: "abc123def456",
  question_times: {
    "1" => 45,  # seconds spent on question 1
    "2" => 120, # seconds spent on question 2
  }
}

# Access via store_accessor
session.browser_info = "Chrome 120.0"
session.ip_address = "192.168.1.100"
session.question_times = { "1" => 45 }
```

### Custom Callbacks

```ruby
# Add custom behavior to state transitions
aasm do
  state :submitted, after_enter: :send_notification_email
  state :marked, after_enter: [:calculate_percentile, :update_leaderboard]
end

private

def send_notification_email
  AssessmentMailer.submission_received(self).deliver_later
end

def calculate_percentile
  # Custom percentile calculation logic
end
```

## Performance Considerations

### Database Indexes

The system includes optimized indexes for common queries:

```sql
-- State-based queries
CREATE INDEX ON assessment_response_sessions (state);
CREATE INDEX ON assessment_response_sessions (assessment_id, state);

-- Time-based queries
CREATE INDEX ON assessment_response_sessions (started_at);
CREATE INDEX ON assessment_response_sessions (completed_at);
CREATE INDEX ON assessment_response_sessions (submitted_at);

-- Scoring queries
CREATE INDEX ON assessment_response_sessions (total_score);

-- Respondent queries
CREATE INDEX ON assessment_response_sessions (respondent_email);
CREATE UNIQUE INDEX ON assessment_response_sessions (respondent_email, assessment_id);
```

### Query Optimization

```ruby
# Efficient loading with includes
sessions = assessment.assessment_response_sessions
                    .includes(:assessment_question_responses, :assessment_response_scores)
                    .recent

# Batch operations
AssessmentResponseSession.where(state: 'submitted')
                         .find_in_batches(batch_size: 100) do |batch|
  batch.each(&:mark!)
end
```

## Testing

Run the demo script to see the system in action:

```bash
ruby test_response_sessions.rb
```

This demonstrates:
- ✅ Session creation and state management
- ✅ State transitions and validations
- ✅ Progress tracking and analytics
- ✅ Integration with marking system
- ✅ Error handling and edge cases

## Integration Points

### With Marking System

- Automatic score calculation when sessions are marked
- Integration with `AssessmentMarkingScheme` for grade boundaries
- Support for multiple marking schemes per assessment

### With Question Responses

- Links individual question responses to sessions
- Tracks response completion for progress calculation
- Maintains referential integrity

### With Analytics

- Real-time statistics and reporting
- Export capabilities (CSV, JSON)
- Historical trend analysis

## Security Considerations

- **Data Privacy**: Respondent information is protected
- **State Integrity**: AASM prevents invalid transitions
- **Access Control**: Controller actions should include authorization
- **Audit Trail**: All state changes are timestamped
- **Data Retention**: Consider implementing cleanup policies

## Future Enhancements

- **Real-time Updates**: WebSocket integration for live progress
- **Advanced Analytics**: Machine learning insights
- **Mobile Optimization**: Progressive Web App features
- **Collaboration**: Multi-respondent sessions
- **Integration**: LTI, SCORM, xAPI support
