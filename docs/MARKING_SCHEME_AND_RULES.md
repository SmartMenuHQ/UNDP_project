# Marking Schemes and Marking Rules Guide

This document explains how automated marking works in the system: what a Marking Scheme is, how Marking Rules operate per question, the supported question and rule types, and how to configure parameters with examples. It is intended for engineers, admins, and integrators who need precise, implementation-level understanding.

## Overview
- A Marking Scheme groups multiple Marking Rules, one or more per question.
- When grading a response, all active rules for that response's question under the selected scheme are evaluated; the highest score from those rules is taken as the score for that question (best-of strategy).
- Scores are stored in `AssessmentResponseScore` with audit details (which rule matched, max possible points, criteria applied).

## Data Models

### AssessmentMarkingScheme
- Fields
  - `name` (string, required)
  - `description` (text)
  - `is_active` (boolean, default true) — Only one active scheme should be used when marking sessions.
  - `total_possible_score` (decimal) — informational; can be recomputed from rules.
  - `settings` (jsonb)
    - `passing_score` (number) — absolute points threshold or percentage depending on use.
    - `grade_boundaries` (object) — map grade letter → minimum percentage, e.g. `{ "A": 90, "B": 80, ... }`.
    - `feedback_templates` (object) — map grade letter → feedback message.
- Key behaviors
  - `grade_response(response)` — find active rules for the question in this scheme; evaluate; take max; record an `AssessmentResponseScore`.
  - `calculate_total_score_for_assessment(assessment_id)` — aggregate over responses, computing totals and grade.

### AssessmentQuestionMarkingRule
- Fields
  - `assessment_question_id` (fk)
  - `assessment_marking_scheme_id` (fk)
  - `rule_type` (string, required)
  - `points` (decimal ≥ 0) — for most rule types; may be ignored for option-based when option points are used.
  - `criteria` (jsonb) — rule-specific configuration (see below).
  - `order` (integer) — evaluation order if needed; not used by the best-of strategy beyond deterministic processing.
  - `is_active` (boolean)
- Validation
  - `rule_type` must be compatible with the question’s type (derived from `assessment_question.available_marking_rule_types`).
  - `points >= 0` (except special handling in option-based where option points may override).
- Evaluation
  - `evaluate_response(response)` dispatches to type-specific methods described below.

## Question Types
All question classes live under `AssessmentQuestions::`:
- `MultipleChoice`
- `Radio`
- `BooleanType`
- `RangeType`
- `DateType`
- `RichText`
- `FileUpload`

Value shapes in `AssessmentQuestionResponse.value` by type:
- MultipleChoice/Radio/BooleanType: managed via join table `selected_options`; `.response_value` returns array of option IDs.
- RangeType: `{ number: 4 }` (or `{ rating: 4 }`); numeric value is used.
- DateType: `{ date: "2025-01-01" }` or date-range/time variants as configured.
- RichText: `{ text: "answer" }`.
- FileUpload: `{ filename, size, content_type, ... }`.

## Rule Types and Criteria
Rule types are enumerated in `config/rule_types.yml` and implemented in `AssessmentQuestionMarkingRule`.

### 1) option_based (MultipleChoice, Radio, BooleanType)
- Purpose: Award points for selecting correct options.
- Compatible question types: MultipleChoice, Radio, BooleanType.
- Scoring:
  - For each selected option:
    - If `option.is_correct_answer?` is true and `option.has_assigned_points?` is true → add `option.points`.
    - Else if correct and no explicit points → add rule `points` (default per-correct award).
  - Optional clamp: if `criteria.minimum_score` is set and total < minimum, raise to that minimum.
- Criteria (examples):
  - `partial_scoring` (boolean) — informational UI hint; actual partial credit is enabled by the additive logic above.
  - `negative_scoring` (boolean) — if implemented, would deduct for incorrect selections (not applied by current code).
  - `minimum_score` (number) — clamp lower bound.
- Example:
```json
{
  "rule_type": "option_based",
  "points": 2,
  "criteria": { "minimum_score": 1 }
}
```

### 2) range_based (RangeType, some DateType)
- Purpose: Award points if numeric value is within inclusive range with optional tolerance.
- Compatible: RangeType, DateType (when numeric encodings are used).
- Criteria:
  - `min` (number, required)
  - `max` (number, required)
  - `tolerance` (number, default 0)
- Scoring: if `value >= (min - tolerance)` and `value <= (max + tolerance)` → award `points`, else 0.
- Example:
```json
{
  "rule_type": "range_based",
  "points": 5,
  "criteria": { "min": 1, "max": 5, "tolerance": 0 }
}
```

### 3) exact_match (RichText, RangeType, DateType)
- Purpose: Award points if response equals any expected value.
- Criteria:
  - `expected_values` (array of strings or numbers)
  - `case_sensitive` (boolean, default false)
  - `trim_whitespace` (boolean, default true)
- Scoring: if normalized response equals any normalized expected → `points` else 0.
- Example:
```json
{
  "rule_type": "exact_match",
  "points": 3,
  "criteria": { "expected_values": ["Yes"], "case_sensitive": false }
}
```

### 4) partial_match (RichText)
- Purpose: Award proportional or full points based on similarity to expected phrases.
- Criteria:
  - `expected_values` (array of phrases)
  - `partial_match_threshold` (number 0..1, default 0.7)
  - `scoring_method` ("proportional" | "all_or_nothing")
- Scoring:
  - Compute similarity to each phrase; take maximum.
  - If ≥ threshold: proportional × `points` or full `points` depending on `scoring_method`.
- Example:
```json
{
  "rule_type": "partial_match",
  "points": 10,
  "criteria": {
    "expected_values": ["safety", "compliance"],
    "partial_match_threshold": 0.75,
    "scoring_method": "proportional"
  }
}
```

### 5) keyword_based (RichText)
- Purpose: Award points based on presence of keywords.
- Criteria:
  - `keywords` (array of strings)
  - `scoring_method` ("proportional" | "all_or_nothing")
- Scoring:
  - Count matching keywords; proportional awards scale by fraction matched; otherwise any match awards `points`.
- Example:
```json
{
  "rule_type": "keyword_based",
  "points": 6,
  "criteria": { "keywords": ["ISO", "audit"], "scoring_method": "proportional" }
}
```

### 6) format_based (RichText)
- Purpose: Validate response against a format.
- Criteria:
  - `format_pattern` (regex string) — generic fallback when `sub_type` is not email/url/phone.
  - Optionally `phone_pattern` when sub_type = phone (default provided).
- Scoring: if pattern matches (or subtype-specific validation passes) → `points` else 0.
- Example:
```json
{
  "rule_type": "format_based",
  "points": 2,
  "criteria": { "format_pattern": "^\\d{3}-\\d{3}$" }
}
```

### 7) step_based (RangeType)
- Purpose: Award points according to numeric intervals.
- Criteria:
  - `step_intervals` (array of { min, max, points? })
- Scoring: first interval that matches grants its `points` (or rule `points` if not specified).
- Example:
```json
{
  "rule_type": "step_based",
  "points": 10,
  "criteria": {
    "step_intervals": [
      { "min": 0, "max": 3, "points": 3 },
      { "min": 4, "max": 7, "points": 7 },
      { "min": 8, "max": 10, "points": 10 }
    ]
  }
}
```

### 8) tolerance_based (RangeType, DateType)
- Purpose: Award points when a numeric response is within an absolute tolerance of an expected numeric value.
- Where to use it: best for numeric questions (RangeType). For DateType, provide a numeric encoding (see below).
- Parameters
  - `expected_value` (number, required): target numeric value
  - `tolerance` (number, required): maximum absolute difference allowed; same units/scale as the response
  - `points` (number): points awarded when condition passes
- Evaluation details
  - Extract numeric value from the response (RangeType reads `value.number`/`value.rating`)
  - If any of `value`, `expected_value`, or `tolerance` is missing → score 0
  - If `abs(value - expected_value) <= tolerance` → award `points`; otherwise 0
- Units and encoding
  - RangeType: ensure both response and expected_value use the same units and scale
  - DateType: encode the date/time numerically for comparison, for example:
    - Epoch day (days since 1970-01-01); set `tolerance` in days
    - Unix timestamp seconds (or minutes/hours); set `tolerance` in the same unit
    - Integer yyyymmdd (e.g., 20250101) — acceptable but not perfectly linear across months, prefer epoch-based encodings for true “days” tolerance
- Examples
  - RangeType (ratings): response `{ number: 4.2 }`, rule `{ points: 5, criteria: { expected_value: 4, tolerance: 0.5 } }` → `abs(4.2 - 4.0) = 0.2 <= 0.5` → 5 points
  - RangeType (temperature): response `{ number: 37.1 }`, rule `{ points: 3, criteria: { expected_value: 37.0, tolerance: 0.3 } }` → 3 points
  - DateType (epoch days): response `{ number: 20000 }`, rule `{ points: 2, criteria: { expected_value: 19998, tolerance: 2 } }` → within ±2 days → 2 points
- Tips
  - Keep `tolerance` non-negative and choose scales carefully (e.g., use decimals if needed)
  - If you need a date window (between two bounds), use `date_range_based`; if you need “close to a specific moment”, use `tolerance_based` with a numeric date encoding

### 9) date_range_based (DateType)
- Purpose: Award points if date falls within start/end range.
- Criteria: `start_date` (YYYY-MM-DD), `end_date` (YYYY-MM-DD)
- Scoring: within range → `points` else 0.

### 10) time_based (DateType with time)
- Purpose: Award points if time is within tolerance of expected time.
- Criteria: `expected_time` (HH:MM[:SS]), `time_tolerance` (seconds)

### 11) overlap_based (DateType with date_range)
- Purpose: Award points based on overlap between response date range and expected range.
- Criteria: `start_date`, `end_date`, `scoring_method` ("proportional"|null)
- Scoring: proportional overlap or full `points` if any overlap and not proportional.

### 12) file_based (FileUpload)
- Purpose: Validate file by a combined criteria object.
- Criteria: `file_criteria` (object)
  - `allowed_types` (array of MIME types)
  - `max_size` (bytes)
- Scoring: file must meet criteria → `points` else 0.

### 13) size_based (FileUpload)
- Purpose: Validate file size only.
- Criteria: `max_size` (bytes)

### 14) type_based (FileUpload)
- Purpose: Validate file content type only.
- Criteria: `allowed_types` (array)

### 15) content_based (FileUpload)
- Purpose: Placeholder for content analysis (custom pipeline may award `points`).

### 16) strength_based (RichText)
- Purpose: Heuristic text “strength” scoring (length, char classes).
- Criteria: `strength_criteria` (object)
  - `min_length` (number) etc.
- Scoring: simple weighted sum fractions of `points`.

### 17) content_analysis (RichText)
- Purpose: Composite text analysis using a list of rules.
- Criteria: `content_analysis_rules` (array of objects), e.g.:
  - `{ "type": "word_count", "min": 50, "max": 150, "points": 4 }`
  - `{ "type": "sentence_count", ... }`
  - `{ "type": "paragraph_count", ... }`
- Scoring: sum awarded points from satisfied rules.

## End-to-End Examples

### MultipleChoice with option-based
- Question: Which are required documents? (multiple selections allowed)
- Options: "Invoice" (correct +2), "Packing List" (correct +2), "Sticker" (incorrect)
- Rule: `option_based`, `points: 1`, `criteria: { minimum_score: 1 }`
- Response: selected [Invoice, Sticker] → Score = 2 (correct Invoice gives +2 via option points; minimum clamp not needed).

### Range with step-based
- Question: Rate safety compliance from 0..10
- Rule: `step_based` with intervals awarding 3/7/10
- Response: `{ number: 6 }` → Score = 7

### RichText with partial_match
- Question: Describe key safety practices
- Rule: `partial_match`, `points: 10`, threshold 0.75, proportional
- Response: mentions both "safety" and "compliance" extensively → Score ~ 8–10 depending on similarity

### FileUpload with file/type/size checks
- Rule: `file_based`, `criteria.file_criteria.allowed_types: ["application/pdf"]`, `criteria.file_criteria.max_size: 1048576`
- Response: PDF of 500KB → Score = `points`

## Operational Guidance
- Prefer one rule per question when possible; add multiple rules if you need alternate scoring paths. Best-of strategy protects against over-penalization.
- Keep `points` consistent across rules to make `total_possible_score` close to the intended maximum; recompute or display totals via the Admin endpoints.
- When using text-based rules, define expectations carefully and consider `trim_whitespace` and `case_sensitive`.
- For file-based rules, always specify MIME types and size limits appropriate to your compliance needs.

## API and Docs
- Admin endpoints manage Schemes and Rules. See RSwag docs for schemas `MarkingScheme` and `MarkingRule`.
- Business endpoints do not expose marking logic but will ultimately rely on active schemes for grading when sessions are completed and marked.

---
If you need more examples for a specific rule type or a migration checklist for moving an existing scheme, open an issue or extend this guide with project-specific cases.
