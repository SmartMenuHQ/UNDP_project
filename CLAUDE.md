# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## IMPORTANT: Frontend Development Focus

**We are ONLY working within the `app/javascript/src/` folder for frontend development.**
- All React components, TypeScript files, and frontend logic should be in `app/javascript/src/`
- Do NOT modify Rails backend code, models, controllers, or views
- Focus only on React/TypeScript frontend implementation that consumes the existing API

## Development Commands

### Running the Application
```bash
# Start all development processes (recommended)
bin/dev

# Or run individually:
bin/rails server               # Rails server (port 3000)
bin/rails tailwindcss:watch   # TailwindCSS watcher
bin/vite dev                   # Vite development server
```

### Database Operations
```bash
rails db:create db:migrate db:seed   # Initial setup
rails db:reset                      # Reset with fresh data
```

### Testing
```bash
bundle exec rspec                    # Run all tests
bundle exec rspec spec/models/       # Run model tests
bundle exec rspec spec/requests/     # Run API tests
```

### Code Quality
```bash
bundle exec rubocop                  # Ruby linting
bundle exec brakeman                 # Security analysis
bundle exec annotaterb               # Update model annotations
```

### Frontend Development
```bash
yarn install                        # Install Node dependencies
yarn build                          # Build frontend assets
bin/vite dev                        # Vite development server with HMR
```

## Application Architecture

### Core System Design
This is a **hybrid Rails 8 + React SPA application** with dual routing systems:
- **Rails routes**: Traditional server-rendered views for assessments management
- **API routes**: RESTful API for React SPA under `/api/v1/`
- **React SPA**: Modern interface accessible at `/app` with client-side routing

### Technology Stack
- **Backend**: Rails 8.0.2, Ruby 3.2.0, PostgreSQL
- **Frontend**: React 19, TypeScript, Vite 5, TailwindCSS 4, Flowbite React
- **Authentication**: Dual system (Rails sessions + JWT tokens)
- **Background Jobs**: Solid Queue (PostgreSQL-based, replaces Redis/Sidekiq)
- **Translation**: Google Cloud Translate + DeepL with Mobility gem
- **Deployment**: Kamal 2 with Docker containers

### Key Models and Relationships

#### Assessment Hierarchy
```
Assessment
├── AssessmentSections (has_many)
│   └── AssessmentQuestions (has_many)
│       └── AssessmentQuestionOptions (has_many)
└── AssessmentResponseSessions (has_many)
    └── AssessmentQuestionResponses (has_many)
```

#### Question Types (STI Pattern)
All inherit from `AssessmentQuestion`:
- `AssessmentQuestions::MultipleChoice`
- `AssessmentQuestions::Radio`
- `AssessmentQuestions::BooleanType`
- `AssessmentQuestions::DateType`
- `AssessmentQuestions::RangeType`
- `AssessmentQuestions::RichText`
- `AssessmentQuestions::FileUpload`

#### User & Session Management
- **User**: Country-based restrictions, admin/regular roles
- **Session**: Token-based with expiration, thread-local `Current.user`
- **Country**: Geographic restrictions for assessments/questions

#### Response Sessions (State Machine)
Uses AASM with states: `draft` → `in_progress` → `completed` → `marked` → `published`

### Authentication System

#### Dual Authentication Approach
1. **Traditional Rails Sessions**: For server-rendered views
2. **Token-based API**: JWT tokens for React SPA and mobile apps

#### Authorization with Pundit
- Policies in `app/policies/` define access control
- Admin vs. regular user permissions
- Country-based content restrictions via `CountryRestrictable` concern

#### Current Context
Thread-local storage pattern:
```ruby
Current.user    # Current authenticated user
Current.session # Current session with token
```

### Frontend Architecture (app/javascript/src ONLY)

#### React Application Structure
```
app/javascript/src/
├── api/              # API client functions and HTTP requests
├── components/       # Reusable React components
│   ├── Cards/        # Card components (AssessmentCard)
│   ├── ErrorBoundary.tsx
│   ├── Listbox/      # Dropdown/select components
│   └── Sidebar/      # Navigation components
├── layouts/          # Page layouts
│   └── DashboardLayout.tsx
├── pages/            # Route/page components
│   ├── 404.tsx
│   ├── index.tsx
│   ├── login.tsx
│   └── register.tsx
└── utils/            # Utility functions
    └── loadPaths.ts  # Dynamic route loading
```

#### Current Components (in app/javascript/src)
- **ErrorBoundary**: React error boundary for graceful error handling
- **DashboardLayout**: Main application shell with navigation
- **Sidebar**: Navigation sidebar component
- **AssessmentCard**: Assessment display card component
- **Listbox**: Dropdown/select UI component

#### Technology Stack (Frontend)
- **React 19**: Latest React with concurrent features
- **TypeScript**: Full type safety across all components
- **Vite 5**: Fast development server with HMR
- **TailwindCSS 4**: Utility-first styling framework
- **Flowbite React**: Comprehensive UI component library
- **Lucide React**: Modern icon library
- **React Router 7**: Client-side routing

#### Build Configuration
- **Entry Point**: `app/javascript/entrypoint/client/index.tsx`
- **Build Tool**: Vite with Ruby plugin integration
- **Hot Module Replacement**: Full HMR support for React components
- **TypeScript Config**: Configured with React-specific types
- **SVG Support**: SVGR plugin for SVG-as-components

#### Development Workflow (Frontend)
1. **Component Development**: Create components in `app/javascript/src/components/`
2. **Page Development**: Create route components in `app/javascript/src/pages/`
3. **API Integration**: Implement API calls in `app/javascript/src/api/`
4. **Styling**: Use TailwindCSS classes with Flowbite React components
5. **Type Safety**: Define TypeScript interfaces for all data structures

#### Frontend Development Patterns

**Component Organization:**
- Use PascalCase for component files (e.g., `AssessmentCard.tsx`)
- Group related components in folders (e.g., `components/Cards/`)
- Export components as default exports
- Use TypeScript interfaces for all props

**API Integration Pattern:**
```typescript
// app/javascript/src/api/assessments.ts
export const fetchAssessments = async (): Promise<Assessment[]> => {
  const response = await fetch('/api/v1/assessments', {
    headers: {
      'Authorization': `Bearer ${getToken()}`,
      'Content-Type': 'application/json'
    }
  });
  const result = await response.json();
  return result.data;
};
```

**Button Styling Standards:**
**IMPORTANT: All buttons must follow this consistent styling pattern:**

```typescript
// ✅ CORRECT - Use this pattern for all buttons
<button className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
  <Icon className="w-4 h-4 mr-2" />
  Button Text
</button>

// ✅ CORRECT - For small action buttons
<button className="p-1.5 rounded-md hover:bg-blue-50 transition-colors group cursor-pointer">
  <Icon className="w-4 h-4 text-gray-600 group-hover:text-blue-600 cursor-pointer" />
</button>

// ❌ AVOID - Don't use Flowbite Button component unless specifically needed
<Button color="gray" size="sm">Button Text</Button>
```

**Button Design Principles:**
- **Secondary Buttons**: `bg-white border border-gray-300 text-gray-700 hover:bg-gray-50`
- **Primary Buttons**: `bg-blue-600 border border-blue-600 text-white hover:bg-blue-700` (for main actions)
- **Action Buttons**: No background, colored hover states (for table actions)
- **Icons**: Use `text-gray-600` with hover color changes
- **Disabled State**: Add `disabled:opacity-50 disabled:cursor-not-allowed`
- **Transitions**: Always include `transition-colors` for smooth interactions

**Error Handling:**
- Use ErrorBoundary component for React error catching
- Handle API errors consistently with error state management
- Display user-friendly error messages

**Styling Conventions:**
- Use TailwindCSS utility classes for styling
- Leverage Flowbite React components for layout (Card, Table, etc.) but avoid Button component
- Use responsive design patterns (sm:, md:, lg:, xl:)
- Follow consistent spacing and color schemes

**Icon Standards:**
- **File Icons**: Use `bg-gray-100` background with `text-gray-600` icons
- **Action Icons**: Use `text-gray-600` with colored hover states
- **Size Consistency**: Use `w-4 h-4` for most icons, `w-5 h-5` for larger buttons

**State Management:**
- Use React hooks (useState, useEffect) for local state
- Consider context for shared state across components
- Implement proper loading and error states
- Use TypeScript for type-safe state updates

### Background Jobs & Services

#### Job System (Solid Queue)
PostgreSQL-based job queue system:
- `TranslationJob`: Automatic content translation
- `MarkingJob`: Assessment scoring
- `BulkMarkingJob`: Batch processing
- `MarkingNotificationJob`: Email notifications

#### Translation Service
Multi-provider translation system:
```ruby
TranslationService.new(provider: :google_cloud)  # Primary
TranslationService.new(provider: :deepl)         # Fallback
```
Supports: English, Spanish, French, Italian, Japanese

#### Services Directory
- `ConditionalVisibilityService`: Question/section visibility logic
- `ResponseValidator`: Response validation
- `TranslationService`: Multi-provider translations

### Advanced Features

#### Conditional Visibility System
Questions and sections can be hidden/shown based on previous responses:
- Stored in JSONB `conditional_visibility` column
- Resolved by `VisibilityResolver` concern
- Supports complex boolean logic

#### Multilingual Content
- **Mobility gem**: Translates model attributes
- **JSONB storage**: Flexible locale-specific content
- **Auto-translation jobs**: Background translation workflow

#### Marking & Scoring System
- **Marking Schemes**: Define scoring strategies
- **Marking Rules**: Specific scoring rules with criteria
- **Rule Types**: Configurable in `config/rule_types.yml`

#### File Upload Configuration
- **Active Storage**: File attachment handling
- **Configurable limits**: File size and type restrictions
- **Metadata storage**: Upload settings in JSONB

### Database Design

#### JSONB Usage
Extensively uses JSONB for flexibility:
- `text` columns for multilingual content
- `meta_data` for question-specific settings
- `conditional_visibility` for dynamic show/hide logic
- `restricted_countries` for geographic limitations

#### Concerns (Mixins)
- `CountryRestrictable`: Adds country-based access control
- `ConditionalVisibility`: Adds dynamic visibility logic
- `VisibilityResolver`: Resolves conditional display rules

### Backend API Structure (For Frontend Consumption)

#### Authentication & Token Management
**Bearer Token Required:** All API calls except public endpoints require `Authorization: Bearer <token>` header

**Auth Endpoints:**
```
POST /api/v1/auth/login          # Get access token
POST /api/v1/auth/refresh        # Refresh token  
GET  /api/v1/auth/me             # Current user info
DELETE /api/v1/auth/logout       # Single session logout
DELETE /api/v1/auth/logout_all   # All sessions logout
```

#### API Response Format
All endpoints return standardized responses:
```json
{
  "status": "ok|error|redirect",
  "data": { /* resource data */ },
  "errors": [],
  "notes": ["Human-readable messages"]
}
```

#### Main Resource Endpoints

**Assessments (Public/Business Access):**
```
GET /api/v1/assessments                    # List available assessments
GET /api/v1/assessments/{id}               # Show assessment details
GET /api/v1/assessments/{id}/sections      # Get assessment sections
GET /api/v1/assessments/{id}/questions     # Get assessment questions
```

**Assessment Taking (Business Namespace):**
```
# Response Session Management
GET  /api/v1/business/assessments/{id}/response-sessions
POST /api/v1/business/assessments/{id}/response-sessions
GET  /api/v1/business/assessments/{id}/response-sessions/{session_id}
PATCH /api/v1/business/assessments/{id}/response-sessions/{session_id}/start

# Section Navigation
GET  /api/v1/business/assessments/{id}/response-sessions/{session_id}/sections/{section_id}
POST /api/v1/business/assessments/{id}/response-sessions/{session_id}/sections/{section_id}/submit
```

**Admin Operations (Admin Namespace):**
```
# Full CRUD for assessments, sections, questions
GET|POST|PATCH|DELETE /api/v1/admin/assessments
GET|POST|PATCH|DELETE /api/v1/admin/assessments/{id}/sections  
GET|POST|PATCH|DELETE /api/v1/admin/assessments/{id}/sections/{section_id}/questions

# User Management
GET|POST|PATCH|DELETE /api/v1/admin/users
POST /api/v1/admin/users/invite
PATCH /api/v1/admin/users/{id}/make_admin

# Countries & Statistics
GET /api/v1/admin/countries
GET /api/v1/admin/countries/{id}/statistics
```

#### Query Parameters & Filtering
**Pagination:** All list endpoints support `page` (default: 1) and `per_page` (default: 25, max: 100)

**Common Filters:**
- `search` - Text search in relevant fields
- `sort_by` - Sort field (varies by endpoint: order, created_at, updated_at)
- `sort_order` - `asc` or `desc`  
- `active` - Filter by active status (boolean)

**Question-specific:**
- `is_required` - Filter by required status
- `question_type` - Filter by type (e.g., `AssessmentQuestions::MultipleChoice`)

#### Key Data Structures

**Assessment:**
```typescript
interface Assessment {
  id: number;
  title: string;
  description: string;
  active: boolean;
  has_country_restrictions: boolean;
  restricted_countries: string[];
  sections_count: number;
  questions_count: number;
  created_at: string;
  updated_at: string;
}
```

**User:**
```typescript
interface User {
  id: number;
  email_address: string;
  first_name: string;
  last_name: string;
  full_name: string;
  display_name: string;
  admin: boolean;
  profile_completed: boolean;
  default_language: string;
  country: Country;
  created_at: string;
  updated_at: string;
}
```

**AssessmentSection:**
```typescript
interface AssessmentSection {
  id: number;
  name: string;
  order: number;
  metadata: Record<string, any>;
  is_conditional: boolean;
  trigger_question_id?: number;
  trigger_response_type: 'option_selected' | 'value_equals' | 'value_range';
  trigger_values: any[];
  operator: 'equals' | 'not_equals' | 'contains' | 'greater_than' | 'less_than';
  has_country_restrictions: boolean;
  restricted_countries: string[];
  questions_count: number;
}
```

**AssessmentQuestion:**
```typescript
interface AssessmentQuestion {
  id: number;
  text: string;
  type: string; // e.g., 'AssessmentQuestions::MultipleChoice'
  question_type: string;
  question_type_name: string;
  sub_type?: string;
  order: number;
  is_required: boolean;
  active: boolean;
  meta_data: Record<string, any>;
  is_conditional: boolean;
  options: AssessmentQuestionOption[];
  section: AssessmentSection;
}
```

**AssessmentResponseSession:**
```typescript
interface AssessmentResponseSession {
  id: number;
  respondent_name: string;
  state: 'started' | 'draft' | 'submitted' | 'completed';
  started_at?: string;
  completed_at?: string;
  submitted_at?: string;
  total_score?: number;
  max_possible_score?: number;
  score_percentage?: number;
  grade?: string;
  progress_percentage: number;
  current_section_id?: number;
  current_question_id?: number;
  user: User;
  assessment: Assessment;
}
```

#### Response Submission Format
When submitting answers to sections:
```typescript
interface QuestionResponse {
  question_id: number;
  selected_option_ids?: number[];  // For multiple choice/radio
  number?: number;                 // For range/number questions
  text?: string;                   // For text questions
  date?: string;                   // For date questions
  boolean?: boolean;               // For boolean questions
}
```

#### Special Features
**Conditional Logic:** Questions/sections can be shown/hidden based on previous responses
**Country Restrictions:** Content can be restricted by user's country
**Navigation Helpers:** Response sessions include navigation links and progress tracking
**Multilingual:** All content supports multiple languages (EN, ES, FR, IT, JA)

### Testing Strategy

#### RSpec Setup
- **Model tests**: Validations, associations, scopes
- **Request tests**: API endpoint testing
- **Factories**: FactoryBot for test data
- **API documentation**: RSwag generates Swagger docs

#### Test Coverage Areas
- Authentication and authorization
- API endpoints (admin and business)
- Model validations and relationships
- Background job processing

### Deployment

#### Kamal 2 (Docker)
- **Containerized deployment** with multi-stage builds
- **Zero-downtime deployments**
- **Environment-specific configurations**
- **Built-in health checks**

#### Security
- **Brakeman**: Static security analysis
- **Content Security Policy**: XSS protection
- **Secure headers**: Security middleware
- **Environment variables**: Sensitive configuration

### Development Patterns

#### Code Organization
- **Concerns**: Shared behavior in `app/models/concerns/`
- **Policies**: Authorization logic in `app/policies/`
- **Services**: Business logic in `app/services/`
- **Jobs**: Background processing in `app/jobs/`

#### Rails Conventions
- **STI**: Single Table Inheritance for question types
- **Nested attributes**: For complex form handling
- **JSONB**: Flexible schema for metadata
- **Thread-local storage**: `Current` object pattern

#### Frontend Patterns
- **Component composition**: Reusable UI components
- **TypeScript interfaces**: Type-safe data structures
- **Error boundaries**: Graceful error handling
- **Dynamic imports**: Code splitting and route loading