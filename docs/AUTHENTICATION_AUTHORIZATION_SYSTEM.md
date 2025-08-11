# Authentication & Authorization System

This document describes the comprehensive authentication and authorization system implemented using Rails 8's built-in authentication generator and Pundit for authorization.

## 🏗️ **System Architecture**

### **Authentication Layer (Rails 8 Generator)**
- **User Model**: Secure password authentication with `has_secure_password`
- **Session Management**: Secure session handling with proper cleanup
- **Password Reset**: Built-in password reset functionality
- **Email Normalization**: Automatic email address normalization

### **Authorization Layer (Pundit)**
- **Policy-based Authorization**: Fine-grained permissions using Pundit policies
- **Role-based Access Control**: Admin vs regular user permissions
- **Resource-specific Permissions**: Different permissions for different resources

### **Country-based Content Filtering**
- **Geographic Restrictions**: Content can be restricted by country
- **Dynamic Filtering**: Real-time filtering based on user's country
- **Multi-level Restrictions**: Assessments, sections, and questions can all have country restrictions

## 📊 **Database Schema**

### **Users Table**
```sql
CREATE TABLE users (
  id                     BIGINT PRIMARY KEY,
  email_address          STRING NOT NULL UNIQUE,
  password_digest        STRING NOT NULL,
  admin                  BOOLEAN DEFAULT FALSE,
  first_name             STRING,
  last_name              STRING,
  country_id             BIGINT REFERENCES countries(id),
  default_language       STRING DEFAULT 'en',
  profile_completed      BOOLEAN DEFAULT FALSE,
  invited_by_id          BIGINT REFERENCES users(id),
  invited_at             TIMESTAMP,
  invitation_accepted_at TIMESTAMP,
  created_at             TIMESTAMP,
  updated_at             TIMESTAMP
);
```

### **Countries Table**
```sql
CREATE TABLE countries (
  id         BIGINT PRIMARY KEY,
  name       STRING NOT NULL,
  code       STRING(3) NOT NULL UNIQUE, -- ISO 3166-1 alpha-3
  region     STRING,
  sort_order INTEGER DEFAULT 0,
  active     BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### **Country Restrictions (JSONB columns)**
```sql
-- Added to assessments, assessment_sections, assessment_questions
restricted_countries      JSONB DEFAULT '[]',
has_country_restrictions  BOOLEAN DEFAULT FALSE
```

## 🔐 **User Management**

### **User Types**
1. **Admin Users**
   - Can create/edit/delete assessments
   - Can invite other users
   - Can manage country restrictions
   - Can promote/demote other users
   - Full system access

2. **Regular Users**
   - Can take assessments (if accessible from their country)
   - Can update their own profile
   - Limited to content available in their country

### **User Lifecycle**
1. **Invitation**: Admin invites user by email
2. **Registration**: User sets password and basic info
3. **Profile Completion**: User completes country and language info
4. **Assessment Access**: User can access allowed assessments

### **Profile Completion**
- **Required Fields**: first_name, last_name, country, default_language
- **Progress Tracking**: Percentage completion calculated automatically
- **Validation**: Profile must be complete to take assessments

## 🌍 **Country-based Restrictions**

### **Restriction Levels**
1. **Assessment Level**: Entire assessment blocked for certain countries
2. **Section Level**: Specific sections blocked (e.g., "Regional Technology" blocked in China)
3. **Question Level**: Individual questions blocked

### **Implementation**
```ruby
# Add restriction to a question/section
question.add_country_restriction("CHN")  # Block in China
section.add_country_restriction(["CHN", "RUS"])  # Block in multiple countries

# Check access
user.can_access_content_with_restrictions?(item.restricted_countries)
item.accessible_to_user?(user)
```

### **JSONB Queries**
```sql
-- Find content restricted for a country
SELECT * FROM assessment_questions
WHERE restricted_countries @> '["CHN"]';

-- Find accessible content for a user
SELECT * FROM assessment_questions
WHERE has_country_restrictions = false
   OR NOT (restricted_countries @> '["USA"]');
```

## 🛡️ **Authorization Policies**

### **Assessment Policy**
```ruby
class AssessmentPolicy < ApplicationPolicy
  def index?
    true  # All users can see available assessments
  end

  def create?
    user&.admin?  # Only admins can create
  end

  def take_assessment?
    user&.profile_completed? &&
      user.can_access_content_with_restrictions?(record.restricted_countries)
  end
end
```

### **User Policy**
```ruby
class UserPolicy < ApplicationPolicy
  def update?
    user&.admin? || user == record  # Admins or self
  end

  def invite?
    user&.admin?  # Only admins can invite
  end

  def make_admin?
    user&.admin? && user != record  # Admins can't promote themselves
  end
end
```

### **Country Policy**
```ruby
class CountryPolicy < ApplicationPolicy
  def index?
    true  # All users can see countries (for profile)
  end

  def create?
    user&.admin?  # Only admins can manage countries
  end

  def destroy?
    user&.admin? && record.can_be_deleted?  # Only if no users
  end
end
```

## 🔧 **Key Features**

### **1. Conditional Visibility Integration**
- Country restrictions work with conditional visibility
- Questions can be both country-restricted AND conditionally visible
- Complex logic: `(country_accessible AND condition_met) = visible`

### **2. Multi-language Support**
- User's default language determines question text display
- Available languages based on user's country/region
- Automatic fallback to English if translation missing

### **3. Invitation System**
- Admin-only user invitation
- Email-based invitation workflow
- Invitation tracking (invited_at, invitation_accepted_at)
- Self-referential user relationships (invited_by)

### **4. Security Features**
- Password strength handled by Rails
- Session management with automatic cleanup
- CSRF protection via Rails defaults
- Authorization checks on every action
- Country-based content filtering

## 📈 **Usage Statistics**

### **User Statistics**
```ruby
User.admins.count                    # Number of admin users
User.with_completed_profiles.count   # Users with complete profiles
User.pending_invitations.count       # Pending invitations
User.by_country(country).count       # Users by country
```

### **Content Restriction Statistics**
```ruby
AssessmentQuestion.restriction_statistics
# => { total: 100, with_restrictions: 25, restriction_percentage: 25.0 }

Country.find_by(code: "CHN").restricted_content_count
# => { questions: 5, sections: 2 }
```

## 🚀 **API Endpoints (Future Implementation)**

### **Authentication Endpoints**
- `POST /session` - Login
- `DELETE /session` - Logout
- `POST /passwords` - Request password reset
- `PATCH /passwords/:token` - Reset password

### **User Management Endpoints**
- `GET /users` - List users (admin only)
- `POST /users` - Invite user (admin only)
- `PATCH /users/:id` - Update user (admin or self)
- `POST /users/:id/promote` - Make admin (admin only)

### **Country Management Endpoints**
- `GET /countries` - List countries
- `POST /countries` - Create country (admin only)
- `PATCH /countries/:id` - Update country (admin only)
- `DELETE /countries/:id` - Delete country (admin only)

### **Assessment Access Endpoints**
- `GET /assessments` - List accessible assessments
- `GET /assessments/:id` - Show assessment (if accessible)
- `POST /assessments/:id/start` - Start assessment session

## 🧪 **Testing Examples**

### **Demo Script Usage**
```bash
# Run the comprehensive demo
rails runner examples/user_management_demo.rb

# Run conditional visibility demo
rails runner examples/conditional_visibility_usage.rb
```

### **Manual Testing**
```ruby
# Create admin user
admin = User.create!(
  email_address: "admin@example.com",
  password: "password123",
  admin: true,
  first_name: "Admin",
  last_name: "User",
  profile_completed: true
)

# Test country restrictions
chinese_user = User.create!(
  email_address: "user@china.com",
  password: "password123",
  country: Country.find_by(code: "CHN"),
  profile_completed: true
)

# Check assessment access
assessment = Assessment.first
assessment.accessible_to_user?(chinese_user)  # May be false if restricted

# Test authorization
policy = AssessmentPolicy.new(chinese_user, assessment)
policy.take_assessment?  # Checks both profile completion and country access
```

## 🔒 **Security Considerations**

### **Password Security**
- Uses Rails' `has_secure_password` with bcrypt
- Minimum password requirements can be added via validations
- Password reset tokens are secure and time-limited

### **Session Security**
- Sessions are server-side managed
- Automatic session cleanup on logout
- Session hijacking protection via Rails defaults

### **Authorization Security**
- All actions protected by Pundit policies
- Fail-safe defaults (deny by default)
- Admin self-promotion prevention
- Resource ownership validation

### **Data Privacy**
- Country-based content filtering respects local laws
- User data restricted to authorized access only
- Audit trail via invitation tracking

## 🎯 **Best Practices**

### **Policy Design**
- Always use `user&.admin?` to handle nil users
- Implement both positive and negative checks
- Use descriptive policy method names
- Test edge cases (nil user, missing associations)

### **Country Restrictions**
- Use ISO 3166-1 alpha-3 country codes
- Validate country codes against active countries
- Provide clear restriction descriptions
- Allow bulk restriction management

### **User Experience**
- Clear error messages for authorization failures
- Graceful degradation for restricted content
- Progressive profile completion prompts
- Intuitive admin interfaces

## 📚 **Related Documentation**

- [Conditional Visibility System](CONDITIONAL_VISIBILITY_SYSTEM.md)
- [Marking System](MARKING_SYSTEM.md)
- [Translation Service](TRANSLATION_SERVICE.md)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)

---

This authentication and authorization system provides a robust foundation for the questionnaire CMS with fine-grained permissions, geographic content filtering, and comprehensive user management capabilities.
