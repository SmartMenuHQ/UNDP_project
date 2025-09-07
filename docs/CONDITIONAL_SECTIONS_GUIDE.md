# Conditional Sections and Questions Guide

This comprehensive guide explains how to create and manage conditional sections and questions using the API. Conditional sections allow you to show or hide entire sections based on previous responses, creating dynamic, personalized assessment experiences.

## Table of Contents
1. [Overview](#overview)
2. [API Endpoints](#api-endpoints)
3. [Conditional Logic Types](#conditional-logic-types)
4. [Configuration Examples](#configuration-examples)
5. [Advanced Scenarios](#advanced-scenarios)
6. [Validation Rules](#validation-rules)
7. [Testing and Debugging](#testing-and-debugging)
8. [Best Practices](#best-practices)

## Overview

### What are Conditional Sections?
Conditional sections are assessment sections that appear or disappear based on how users answer previous questions. This enables:
- **Personalized assessments**: Show relevant sections based on user profile
- **Branching logic**: Different paths through the assessment
- **Skip patterns**: Avoid irrelevant questions
- **Progressive disclosure**: Reveal complexity gradually

### Key Concepts
- **Trigger Question**: The question whose answer determines visibility
- **Target Section**: The section that becomes visible/hidden
- **Visibility Conditions**: The rules that determine when to show the section
- **Evaluation Order**: Sections are evaluated in order, so trigger questions must come before conditional sections

## API Endpoints

### Base URL
All admin endpoints are under `/api/v1/admin/assessments/{assessment_id}/sections`

### Create Conditional Section
```http
POST /api/v1/admin/assessments/{assessment_id}/sections
Content-Type: application/json
Authorization: Bearer {admin_token}
```

### Update Conditional Section
```http
PATCH /api/v1/admin/assessments/{assessment_id}/sections/{section_id}
Content-Type: application/json
Authorization: Bearer {admin_token}
```

### Get Section Details
```http
GET /api/v1/admin/assessments/{assessment_id}/sections/{section_id}
Authorization: Bearer {admin_token}
```

## Conditional Logic Types

### 1. Option-Based Conditions
For Multiple Choice, Radio, and Boolean questions.

#### Single Option Selected
```json
{
  "trigger_response_type": "option_selected",
  "trigger_values": [42],
  "operator": "contains"
}
```

#### Multiple Options Selected (ANY)
```json
{
  "trigger_response_type": "option_selected",
  "trigger_values": [42, 43, 44],
  "operator": "contains"
}
```

#### Multiple Options Selected (ALL)
```json
{
  "trigger_response_type": "option_selected",
  "trigger_values": [42, 43],
  "operator": "contains_all"
}
```

### 2. Value-Based Conditions
For text, numeric, and other input types.

#### Exact Value Match
```json
{
  "trigger_response_type": "value_equals",
  "trigger_values": ["Yes"],
  "operator": "equals"
}
```

#### Value Range
```json
{
  "trigger_response_type": "value_range",
  "trigger_values": [10, 50],
  "operator": "between"
}
```

#### Numeric Comparisons
```json
{
  "trigger_response_type": "value_comparison",
  "trigger_values": [100],
  "operator": "greater_than"
}
```

### 3. Complex Conditions
Multiple conditions with logical operators.

#### AND Logic
```json
{
  "logic_operator": "and",
  "conditions": [
    {
      "trigger_question_id": 123,
      "trigger_response_type": "option_selected",
      "trigger_values": [42],
      "operator": "contains"
    },
    {
      "trigger_question_id": 124,
      "trigger_response_type": "value_range",
      "trigger_values": [10, 50],
      "operator": "between"
    }
  ]
}
```

#### OR Logic
```json
{
  "logic_operator": "or",
  "conditions": [
    {
      "trigger_question_id": 123,
      "trigger_response_type": "option_selected",
      "trigger_values": [42],
      "operator": "contains"
    },
    {
      "trigger_question_id": 125,
      "trigger_response_type": "value_equals",
      "trigger_values": ["Premium"],
      "operator": "equals"
    }
  ]
}
```

## Configuration Examples

### Example 1: Business Type Branching
Show different sections based on business type selection.

#### Step 1: Create the Trigger Question
```http
POST /api/v1/admin/assessments/123/sections/1/questions
```
```json
{
  "question": {
    "text": {
      "en": "What type of business are you?",
      "es": "¿Qué tipo de negocio tienes?"
    },
    "type": "AssessmentQuestions::Radio",
    "is_required": true,
    "order": 1,
    "options_attributes": [
      {
        "text": {"en": "Sole Proprietorship", "es": "Propietario único"},
        "order": 1
      },
      {
        "text": {"en": "Partnership", "es": "Sociedad"},
        "order": 2
      },
      {
        "text": {"en": "Corporation", "es": "Corporación"},
        "order": 3
      },
      {
        "text": {"en": "LLC", "es": "LLC"},
        "order": 4
      }
    ]
  }
}
```

#### Step 2: Create Conditional Section for Corporations
```http
POST /api/v1/admin/assessments/123/sections
```
```json
{
  "section": {
    "name": "Corporate Governance",
    "description": "Questions specific to corporate structure",
    "order": 3,
    "is_conditional": true,
    "visibility_conditions": {
      "trigger_question_id": 456,
      "trigger_response_type": "option_selected",
      "trigger_values": [789],
      "operator": "contains",
      "description": "Show when Corporation is selected"
    }
  }
}
```

### Example 2: Revenue-Based Sections
Show different compliance sections based on annual revenue.

#### Create Revenue Question
```json
{
  "question": {
    "text": {
      "en": "What is your annual revenue?",
      "es": "¿Cuáles son sus ingresos anuales?"
    },
    "type": "AssessmentQuestions::RangeType",
    "is_required": true,
    "validation_rule_set": {
      "min_value": 0,
      "max_value": 10000000,
      "step": 1000
    }
  }
}
```

#### Create Small Business Section
```json
{
  "section": {
    "name": "Small Business Compliance",
    "order": 4,
    "is_conditional": true,
    "visibility_conditions": {
      "trigger_question_id": 457,
      "trigger_response_type": "value_range",
      "trigger_values": [0, 100000],
      "operator": "between",
      "description": "Show for businesses with revenue under $100K"
    }
  }
}
```

#### Create Enterprise Section
```json
{
  "section": {
    "name": "Enterprise Compliance",
    "order": 5,
    "is_conditional": true,
    "visibility_conditions": {
      "trigger_question_id": 457,
      "trigger_response_type": "value_comparison",
      "trigger_values": [1000000],
      "operator": "greater_than",
      "description": "Show for businesses with revenue over $1M"
    }
  }
}
```

### Example 3: Multi-Condition Logic
Show section only if user is a corporation AND has high revenue.

```json
{
  "section": {
    "name": "Advanced Corporate Requirements",
    "order": 6,
    "is_conditional": true,
    "visibility_conditions": {
      "logic_operator": "and",
      "conditions": [
        {
          "trigger_question_id": 456,
          "trigger_response_type": "option_selected",
          "trigger_values": [789],
          "operator": "contains"
        },
        {
          "trigger_question_id": 457,
          "trigger_response_type": "value_comparison",
          "trigger_values": [5000000],
          "operator": "greater_than"
        }
      ],
      "description": "Show for corporations with revenue > $5M"
    }
  }
}
```

### Example 4: Geographic Branching
Show different sections based on country selection.

```json
{
  "section": {
    "name": "US Regulatory Requirements",
    "order": 7,
    "is_conditional": true,
    "visibility_conditions": {
      "trigger_question_id": 458,
      "trigger_response_type": "value_equals",
      "trigger_values": ["US", "USA", "United States"],
      "operator": "in",
      "description": "Show for US-based businesses"
    }
  }
}
```

## Advanced Scenarios

### Nested Conditional Sections
Create sections that depend on other conditional sections.

```json
{
  "section": {
    "name": "California State Requirements",
    "order": 8,
    "is_conditional": true,
    "visibility_conditions": {
      "logic_operator": "and",
      "conditions": [
        {
          "trigger_question_id": 458,
          "trigger_response_type": "value_equals",
          "trigger_values": ["US"],
          "operator": "equals"
        },
        {
          "trigger_question_id": 459,
          "trigger_response_type": "value_equals",
          "trigger_values": ["CA", "California"],
          "operator": "in"
        }
      ]
    }
  }
}
```

### Dynamic Question Visibility
Individual questions can also be conditional within sections.

```json
{
  "question": {
    "text": {
      "en": "Please provide your EIN number"
    },
    "type": "AssessmentQuestions::RichText",
    "is_conditional": true,
    "visibility_conditions": {
      "trigger_question_id": 456,
      "trigger_response_type": "option_selected",
      "trigger_values": [789, 790],
      "operator": "contains",
      "description": "Show EIN field for corporations and LLCs"
    }
  }
}
```

### Time-Based Conditions
Show sections based on date responses.

```json
{
  "section": {
    "name": "New Business Incentives",
    "is_conditional": true,
    "visibility_conditions": {
      "trigger_question_id": 460,
      "trigger_response_type": "date_comparison",
      "trigger_values": ["2023-01-01"],
      "operator": "after",
      "description": "Show for businesses started after 2023"
    }
  }
}
```

## Validation Rules

### Order Dependencies
- Trigger questions must appear before conditional sections
- Questions within conditional sections cannot trigger conditions for earlier sections
- Circular dependencies are not allowed

### Data Type Compatibility
| Question Type | Compatible Operators | Example Values |
|---------------|---------------------|----------------|
| MultipleChoice/Radio | `contains`, `contains_all`, `not_contains` | `[option_id1, option_id2]` |
| BooleanType | `equals` | `[true]` or `[false]` |
| RichText | `equals`, `contains`, `matches` | `["Yes", "No"]` |
| RangeType | `equals`, `between`, `greater_than`, `less_than` | `[100]` or `[10, 50]` |
| DateType | `equals`, `before`, `after`, `between` | `["2023-01-01"]` |

### Required Fields
- `trigger_question_id`: Must reference existing question
- `trigger_response_type`: Must match question type capabilities
- `trigger_values`: Must be appropriate for the operator
- `operator`: Must be compatible with response type

## Testing and Debugging

### Test Conditional Logic
Use the visibility summary endpoint to test conditions:

```http
GET /api/v1/assessments/{assessment_id}/visibility_summary
```

Response includes which sections would be visible for given responses:
```json
{
  "visible_sections": [
    {"id": 1, "name": "Basic Information"},
    {"id": 3, "name": "Corporate Governance"}
  ],
  "hidden_sections": [
    {"id": 4, "name": "Small Business Compliance"}
  ],
  "conditional_logic": {
    "section_3": {
      "condition": "question_456 option_selected contains [789]",
      "result": "visible",
      "trigger_response": "Corporation"
    }
  }
}
```

### Debug Session Flow
Monitor section visibility during a session:

```http
GET /api/v1/business/assessments/{assessment_id}/response-sessions/{session_id}
```

The response includes current visibility state:
```json
{
  "response_session": {
    "id": 123,
    "state": "in_progress"
  },
  "meta": {
    "visible_sections": [1, 2, 3],
    "current_section_id": 2,
    "next_section_id": 3,
    "conditional_evaluations": {
      "section_3": "visible_due_to_question_456_response"
    }
  }
}
```

### Common Issues and Solutions

#### Issue: Section Not Appearing
**Symptoms**: Conditional section doesn't show despite meeting conditions
**Solutions**:
1. Check trigger question ID is correct
2. Verify option IDs match exactly
3. Ensure trigger question comes before conditional section
4. Check data types match (string vs number)

#### Issue: Section Always Visible
**Symptoms**: Conditional section shows regardless of responses
**Solutions**:
1. Verify `is_conditional: true` is set
2. Check `visibility_conditions` are properly formatted
3. Ensure operator matches data type

#### Issue: Complex Logic Not Working
**Symptoms**: AND/OR conditions not evaluating correctly
**Solutions**:
1. Test each condition individually
2. Verify `logic_operator` is set correctly
3. Check all referenced questions exist

## Best Practices

### 1. Design Principles
- **Keep it simple**: Start with basic conditions before adding complexity
- **User-friendly**: Ensure conditional flow makes sense to users
- **Performance**: Limit deep nesting and complex conditions
- **Maintainability**: Document complex conditional logic

### 2. Naming Conventions
```json
{
  "section": {
    "name": "Corporate Governance (Conditional)",
    "description": "Shown when business type is Corporation"
  }
}
```

### 3. Error Handling
Always include descriptive error messages:
```json
{
  "visibility_conditions": {
    "description": "Show when user selects Corporation (option 789) in question 456"
  }
}
```

### 4. Testing Strategy
1. **Unit Testing**: Test each condition individually
2. **Integration Testing**: Test complete conditional flows
3. **User Testing**: Validate the logical flow makes sense
4. **Edge Cases**: Test with missing responses, invalid data

### 5. Performance Optimization
- Use simple conditions when possible
- Avoid deeply nested conditional sections
- Consider caching for complex evaluations
- Monitor response times for assessments with many conditions

### 6. Accessibility Considerations
- Provide clear indicators when sections appear/disappear
- Ensure screen readers can understand the conditional flow
- Test with assistive technologies

### 7. Internationalization
Ensure conditional logic works across languages:
```json
{
  "trigger_values": ["Yes", "Sí", "Oui"],
  "operator": "in"
}
```

### 8. Version Control
When updating conditional logic:
1. Test thoroughly in staging
2. Consider impact on existing sessions
3. Provide migration path for data changes
4. Document changes in release notes

## API Response Examples

### Successful Section Creation
```json
{
  "data": {
    "section": {
      "id": 123,
      "name": "Corporate Governance",
      "order": 3,
      "is_conditional": true,
      "visibility_conditions": {
        "trigger_question_id": 456,
        "trigger_response_type": "option_selected",
        "trigger_values": [789],
        "operator": "contains"
      }
    }
  },
  "meta": {
    "message": "Section created successfully"
  }
}
```

### Validation Error
```json
{
  "error": {
    "type": "ValidationError",
    "message": "Invalid visibility conditions",
    "details": {
      "errors": [
        "Trigger question must exist",
        "Trigger values must be valid option IDs"
      ]
    }
  }
}
```

This guide provides comprehensive coverage of conditional sections and questions. For additional support, refer to the API documentation or contact the development team.
