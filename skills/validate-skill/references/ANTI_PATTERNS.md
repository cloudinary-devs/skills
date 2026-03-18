# Common Anti-Patterns in Agent Skills

This reference lists common anti-patterns found in Agent Skills with specific examples and fixes.

## Structural Anti-Patterns

### ❌ Windows-Style Paths

**Problem:** Using backslashes in file paths
```
scripts\helper.py
references\examples.md
```

**Fix:** Always use forward slashes
```
scripts/helper.py
references/examples.md
```

**Why:** Skills may be used across platforms; forward slashes work everywhere.

---

### ❌ Too Many Options Without Defaults

**Problem:** Overwhelming the agent with choices
```
You can use approach A, or approach B, or approach C, or approach D...
Each has different trade-offs...
```

**Fix:** Provide one recommended default with escape hatches
```
Use approach A (recommended for most cases).

For edge cases:
- Use approach B when [specific condition]
- Use approach C when [specific condition]
```

**Why:** Agents need clear guidance; too many options slow decision-making.

---

### ❌ Time-Sensitive Information

**Problem:** Instructions that expire
```
Before August 2025, use the old API...
The new version will be available in Q2 2024...
```

**Fix:** Use "old patterns" or "deprecated" sections
```
## Current Approach
Use the v2 API...

<details>
<summary>Legacy approach (deprecated)</summary>

For older systems, use the v1 API...
</details>
```

**Why:** Skills should be evergreen; time-based instructions become confusing.

---

### ❌ Deep File Nesting

**Problem:** Reference files that reference other files
```
SKILL.md → references/guide.md → references/advanced/details.md → references/advanced/examples/case1.md
```

**Fix:** Keep references one level deep from SKILL.md
```
SKILL.md → references/guide.md
SKILL.md → references/advanced-details.md
SKILL.md → references/examples.md
```

**Why:** Deep nesting increases token cost and complexity.

## Content Anti-Patterns

### ❌ Verbose Explanations of Common Knowledge

**Problem:** Teaching the agent things it already knows
```
Python is a programming language that uses indentation to define code blocks.
Variables store data and can be of different types like strings and numbers.
```

**Fix:** Assume agent knowledge, focus on specifics
```
Use 4-space indentation (project convention).
Variable naming: use snake_case for local vars, UPPER_CASE for constants.
```

**Why:** Agents already know programming basics; save tokens for unique information.

---

### ❌ First or Second Person Language

**Problem:** Description uses "I" or "You"
```
name: helper
description: I can help you with various tasks. You can use this when you need assistance.
```

**Fix:** Use third person, be specific
```
name: git-workflow
description: Automates Git workflows including branching, committing, and PR creation. Use when managing Git operations or when the user mentions commits, branches, or pull requests.
```

**Why:** Descriptions should be factual and discoverable, not conversational.

---

### ❌ Inconsistent Terminology

**Problem:** Mixing synonyms unnecessarily
```
Use the API endpoint to call the service route...
Send the request to the URL endpoint...
The API route will return...
```

**Fix:** Choose one term and use consistently
```
Use the API endpoint to call the service...
Send the request to the endpoint...
The endpoint will return...
```

**Why:** Consistency improves clarity and reduces cognitive load.

---

### ❌ Abstract or Placeholder Examples

**Problem:** Examples that don't show real patterns
```
Step 1: Do the first thing
Step 2: Do the second thing
Example: thing_name: value
```

**Fix:** Show concrete, realistic examples
```
Step 1: Extract form fields using PyPDF2
Step 2: Validate field values against schema

Example:
{
  "name": "John Smith",
  "email": "john@example.com",
  "age": 25
}
```

**Why:** Concrete examples help agents understand expected formats and patterns.

---

### ❌ Vague Skill Names

**Problem:** Generic names that don't indicate purpose
```
helper
utils
tools
general
```

**Fix:** Specific, descriptive names
```
pdf-form-filler
git-workflow-automation
cloudinary-transformations
docker-compose-generator
```

**Why:** Specific names improve discoverability and clarity.

## Workflow Anti-Patterns

### ❌ Punting to the Agent

**Problem:** Scripts that just tell the agent what to do
```python
# Script: process_data.py
print("Now process the data file")
print("Make sure to handle edge cases")
print("Validate the output")
```

**Fix:** Scripts should DO the work
```python
# Script: process_data.py
import json
import sys

def process_data(input_file):
    try:
        with open(input_file) as f:
            data = json.load(f)
        
        # Process with edge case handling
        processed = validate_and_transform(data)
        
        return processed
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    result = process_data(sys.argv[1])
    print(json.dumps(result))
```

**Why:** Scripts should reduce agent work, not add extra steps.

---

### ❌ Missing Validation Steps

**Problem:** No feedback loops for quality-critical operations
```
1. Modify the database schema
2. Deploy to production
3. Done
```

**Fix:** Include validation between steps
```
1. Modify the database schema
2. Run schema validation: `npm run validate-schema`
3. Check validation output - must show 0 errors
4. Run test suite: `npm test`
5. Verify all tests pass before proceeding
6. Deploy to production
```

**Why:** Catch errors early before they compound.

---

### ❌ Unclear Decision Points

**Problem:** Ambiguous conditional logic
```
Depending on the situation, you might want to use A or B.
Consider the trade-offs and choose accordingly.
```

**Fix:** Explicit conditions
```
Use approach A when:
- File size < 1MB
- Real-time processing required

Use approach B when:
- File size > 1MB
- Batch processing acceptable
```

**Why:** Clear conditions enable autonomous decision-making.

---

### ❌ Too Much or Too Little Freedom

**Problem:** Wrong degree of freedom for task type

**Fragile operation with too much freedom:**
```
Modify the Kubernetes deployment configuration as needed.
```

**Fix:** Provide specific script
```
Run: `python scripts/update-k8s-config.py --replicas 3 --image app:v2`
```

**Creative task with too little freedom:**
```
Run: `generate-blog-post.py --title "..." --length 500 --tone professional`
```

**Fix:** Provide guidance, not rigid script
```
Write a blog post that:
- Engages readers with a compelling hook
- Provides actionable insights
- Uses clear, conversational tone
- Includes relevant examples
```

**Why:** Match the degree of freedom to the task's nature.

## Code Anti-Patterns

### ❌ Magic Numbers / Voodoo Constants

**Problem:** Unexplained values
```python
threshold = 0.73  # Why this value?
max_iterations = 47  # Where did this come from?
```

**Fix:** Justify or parameterize
```python
# Threshold based on 95th percentile from validation dataset
threshold = 0.73
# Maximum iterations to stay within 30-second timeout (measured: ~0.64s per iteration)
max_iterations = 47
```

**Why:** Makes code maintainable and decisions transparent.

---

### ❌ Missing Error Handling

**Problem:** Scripts that fail silently or with unclear errors
```python
def process_file(path):
    with open(path) as f:
        data = json.load(f)
    return transform(data)
```

**Fix:** Explicit error handling with helpful messages
```python
def process_file(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: File not found: {path}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in {path}: {e}", file=sys.stderr)
        sys.exit(1)
    
    try:
        return transform(data)
    except Exception as e:
        print(f"Error during transformation: {e}", file=sys.stderr)
        sys.exit(1)
```

**Why:** Clear errors help agents understand and fix issues quickly.

---

### ❌ Undocumented Dependencies

**Problem:** Scripts that fail due to missing packages
```python
import obscure_package  # Not in standard library
```

**Fix:** Document requirements clearly
```
## Requirements

Install required packages:
```bash
pip install obscure-package==1.2.3
```

Or add to requirements.txt:
```
obscure-package>=1.2.3
```
```

**Why:** Agents can install dependencies if they know what's needed.

## Description Anti-Patterns

### ❌ Vague or Generic Description

**Problem:**
```yaml
name: helper
description: Helps with various tasks
```

**Fix:**
```yaml
name: docker-compose-generator
description: Generates docker-compose.yml files from service requirements with best practices. Use when creating Docker Compose configurations, setting up multi-container applications, or when the user mentions Docker, containers, or docker-compose.
```

**Why:** Specific descriptions enable discovery through keywords.

---

### ❌ Description Too Short

**Problem:**
```yaml
name: api-client
description: API client
```

**Fix:**
```yaml
name: rest-api-client
description: Create REST API clients with authentication, error handling, and retry logic. Use when building API integrations, implementing HTTP clients, or when the user mentions REST APIs, endpoints, or API calls.
```

**Why:** Descriptions should include both WHAT and WHEN for effective discovery.

---

### ❌ Description Too Long

**Problem:**
```yaml
name: data-processor
description: This is a comprehensive skill that helps you process data files including CSV, JSON, and XML formats. It can handle large files efficiently using streaming, validate data against schemas, transform data between formats, filter and aggregate data, handle missing values, detect anomalies, generate statistics, create visualizations, export to databases, and much more. Use this whenever you need to work with data in any way.
```

**Fix:**
```yaml
name: data-processor
description: Process, validate, and transform CSV, JSON, and XML files with schema validation and format conversion. Use when parsing data files, converting formats, validating schemas, or when the user mentions data processing, CSV, or JSON.
```

**Why:** Stay under 1024 characters; be specific but concise.

## Checklist Item Anti-Patterns

### ❌ Implementation Details in Checklist

**Problem:** Checklist items that teach how to do something
```
- [ ] Functions should be documented with docstrings that explain parameters, return values, and include usage examples
```

**Fix:** Keep checklist items verifiable
```
- [ ] All functions have docstrings
```

**Why:** Checklists are for verification, not instruction.

---

### ❌ Overly Granular Checks

**Problem:** Too many micro-checks
```
- [ ] File has .py extension
- [ ] File uses UTF-8 encoding
- [ ] File has import statements at top
- [ ] File has blank line after imports
- [ ] Functions are defined after imports
```

**Fix:** Group related checks
```
- [ ] Python file structure follows conventions (imports at top, UTF-8 encoding)
- [ ] Code organization is logical (functions, classes, main block)
```

**Why:** Balance thoroughness with practicality.

## Organization Anti-Patterns

### ❌ Flat File Structure for Complex Skills

**Problem:** Everything in SKILL.md
```
my-skill/
└── SKILL.md (1200 lines with examples, API docs, etc.)
```

**Fix:** Use progressive disclosure
```
my-skill/
├── SKILL.md (300 lines - core instructions)
├── references/
│   ├── api-reference.md
│   ├── examples.md
│   └── advanced-usage.md
└── scripts/
    └── helper.py
```

**Why:** Keeps core instructions concise, details available when needed.

---

### ❌ Multiple Skills in One File

**Problem:** One skill trying to do too much
```
name: dev-tools
description: Helps with Git, Docker, Kubernetes, CI/CD, testing, and deployment
```

**Fix:** Split into focused skills
```
name: git-workflow
description: Automates Git branching, committing, and PR creation...

name: docker-helper  
description: Creates and manages Docker containers and images...
```

**Why:** Smaller, focused skills are more maintainable and discoverable.

---

### ❌ Mixing Concerns

**Problem:** Unrelated functionality in one skill
```
name: backend-helper
description: Database queries AND API creation AND email sending AND file uploads
```

**Fix:** Separate by domain
```
name: database-query-builder
description: Generate and optimize SQL queries...

name: api-endpoint-generator
description: Create REST API endpoints with validation...
```

**Why:** Single responsibility makes skills more reusable and clear.

## Language Anti-Patterns

### ❌ Hedge Words

**Problem:** Uncertain language
```
This might help with...
You could potentially try...
Perhaps consider using...
```

**Fix:** Confident, direct language
```
Use this to...
Apply this transformation...
Run this command...
```

**Why:** Clear instructions enable autonomous execution.

---

### ❌ Marketing Language

**Problem:** Overselling capabilities
```
This amazing skill will revolutionize your workflow!
The ultimate solution for all your needs!
```

**Fix:** Factual, specific descriptions
```
Automates Git commit message generation following conventional commit format.
Reduces manual PR creation time by handling boilerplate.
```

**Why:** Facts help agents understand actual capabilities.

---

### ❌ Passive Voice

**Problem:** Unclear actor
```
The file should be processed...
Validation needs to be performed...
```

**Fix:** Active voice with clear instructions
```
Process the file using...
Run validation with...
```

**Why:** Active voice is clearer and more direct.

## Example Anti-Patterns

### ❌ Placeholder Examples

**Problem:** Examples that don't show real patterns
```
Example:
{
  "field1": "value1",
  "field2": "value2"
}
```

**Fix:** Show realistic data
```
Example:
{
  "customer_id": "cust_1A2B3C",
  "order_total": 149.99,
  "status": "completed"
}
```

**Why:** Realistic examples show expected data types and formats.

---

### ❌ Incomplete Examples

**Problem:** Examples that don't run/work
```python
# Example:
result = api.fetch()
print(result)
```

**Fix:** Complete, runnable examples
```python
# Example:
import requests

response = requests.get('https://api.example.com/data', 
                       headers={'Authorization': 'Bearer token'})
result = response.json()
print(f"Found {len(result['items'])} items")
```

**Why:** Complete examples show all necessary steps.

---

### ❌ Examples Without Context

**Problem:** Examples without explanation of when to use
```
Example 1: [code]
Example 2: [code]
Example 3: [code]
```

**Fix:** Explain when each applies
```
**Use Example 1** when handling single files:
[code]

**Use Example 2** when processing batches:
[code]

**Use Example 3** when streaming large datasets:
[code]
```

**Why:** Context helps agents choose the right pattern.

## Workflow Anti-Patterns

### ❌ Missing Prerequisites

**Problem:** Assuming setup is done
```
Step 1: Run the migration
Step 2: Restart the service
```

**Fix:** Include prerequisites
```
Prerequisites:
- Database connection configured in .env
- Migration files in db/migrations/
- Service is running

Steps:
1. Run the migration: `npm run migrate`
2. Restart the service: `npm run restart`
```

**Why:** Missing prerequisites cause failures.

---

### ❌ No Error Recovery

**Problem:** Workflow stops at first error
```
1. Clone repository
2. Install dependencies
3. Run tests
```

**Fix:** Include error handling
```
1. Clone repository
   - If error: Check network connection and repository access
2. Install dependencies
   - If error: Verify package manager is installed (npm/yarn)
3. Run tests
   - If failures: Check test output and fix before proceeding
```

**Why:** Helps agents handle issues autonomously.

---

### ❌ Ambiguous Success Criteria

**Problem:** Unclear when step is complete
```
1. Optimize the code
2. Test the changes
3. Deploy
```

**Fix:** Clear success criteria
```
1. Optimize the code
   ✅ Success: Function runtime < 100ms
2. Test the changes
   ✅ Success: All tests pass (npm test shows 0 failures)
3. Deploy
   ✅ Success: Health check returns 200 status
```

**Why:** Clear criteria enable autonomous validation.

## Documentation Anti-Patterns

### ❌ Assuming Context

**Problem:** Instructions that assume unstated context
```
Run the script with the usual parameters.
Use the standard configuration.
```

**Fix:** Be explicit
```
Run: `python scripts/process.py --input data.csv --output results.json`
Use configuration from config/default.yml
```

**Why:** Agents need explicit instructions, not assumed knowledge.

---

### ❌ Missing Edge Cases

**Problem:** Only covering happy path
```
Read the file and process it.
```

**Fix:** Cover edge cases
```
Read the file and process it.

Edge cases:
- Empty file: Skip processing, log warning
- File > 100MB: Use streaming processor
- Invalid format: Return error with line number
```

**Why:** Real-world usage involves edge cases.

---

### ❌ Incomplete API Documentation

**Problem:** Missing parameter details
```
Function: process(input)
Returns: result
```

**Fix:** Complete signature with types
```
Function: process(input: str, options: dict = None) -> dict

Parameters:
- input: Path to input file (CSV, JSON, or XML)
- options: Optional configuration dict
  - validate: bool (default True) - Run validation
  - output_format: str (default 'json') - Output format

Returns: dict with keys:
- success: bool - Processing status
- data: list - Processed records
- errors: list - Any errors encountered
```

**Why:** Complete docs enable correct usage.

## Testing Anti-Patterns

### ❌ No Test Instructions

**Problem:** Skill provides code without test guidance
```
Here's the implementation: [code]
```

**Fix:** Include test instructions
```
Here's the implementation: [code]

To test:
1. Run unit tests: `pytest tests/`
2. Verify output matches expected format
3. Test edge cases: empty input, large files, invalid data
```

**Why:** Testing ensures quality and catches issues early.

---

### ❌ Tests That Don't Actually Test

**Problem:** Tests that always pass
```python
def test_function():
    result = my_function()
    assert True  # Always passes!
```

**Fix:** Meaningful assertions
```python
def test_function():
    result = my_function(input_data)
    assert result['status'] == 'success'
    assert len(result['items']) == 3
    assert result['items'][0]['name'] == 'expected_value'
```

**Why:** Tests should verify actual behavior.

## Quality Checklist

Use this to catch anti-patterns in your skill:

- [ ] No Windows-style paths (backslashes)
- [ ] No time-sensitive information (or properly sectioned)
- [ ] No first/second person in description
- [ ] No vague skill names
- [ ] No verbose common knowledge explanations
- [ ] No inconsistent terminology
- [ ] No abstract/placeholder examples
- [ ] No missing validation steps
- [ ] No ambiguous decision points
- [ ] No magic numbers without explanation
- [ ] No missing error handling
- [ ] No undocumented dependencies
- [ ] Clear success criteria for each step
- [ ] Appropriate degree of freedom for task type
- [ ] File references are one level deep
- [ ] Examples are concrete and realistic

## Additional Resources

- [Agent Skills Specification](https://agentskills.io/specification)
- [Complete Validation Checklist](CHECKLIST.md)
