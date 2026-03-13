# Complete Skill Validation Checklist

Use this comprehensive checklist for thorough skill validation.

## Core Quality

- [ ] Name is max 64 characters
- [ ] Name uses lowercase letters, numbers, and hyphens only
- [ ] Name doesn't start or end with a hyphen
- [ ] Name is descriptive and specific (not vague like "helper" or "utils")
- [ ] Description exists and is non-empty
- [ ] Description is max 1024 characters
- [ ] Description is written in third person
- [ ] Description includes what the skill does (capabilities)
- [ ] Description includes when to use it (trigger scenarios)
- [ ] Description is specific and includes key terms
- [ ] SKILL.md body is under 500 lines
- [ ] Additional details are in separate files (if needed)
- [ ] No time-sensitive information (or in "old patterns" section)
- [ ] Consistent terminology throughout
- [ ] Examples are concrete, not abstract
- [ ] File references are one level deep
- [ ] Progressive disclosure used appropriately
- [ ] Workflows have clear steps

## Content Writing

- [ ] No unnecessary explanations of common knowledge
- [ ] Focus on information the agent doesn't already have
- [ ] Each paragraph justifies its token cost
- [ ] No verbose introductions or excessive background
- [ ] Instructions are procedural, not theoretical
- [ ] Clear, actionable steps rather than abstract guidance

## Structure and Organization

- [ ] Logical section organization
- [ ] Multi-step processes have numbered steps
- [ ] Checklists provided for complex workflows
- [ ] Clear headings and subheadings
- [ ] Easy to scan and navigate
- [ ] Related information grouped together

## Examples and Templates

- [ ] Examples show actual inputs and outputs
- [ ] Examples are specific, not placeholder text
- [ ] Templates provided for structured outputs
- [ ] Examples demonstrate the expected format
- [ ] Sufficient examples for pattern recognition

## File and Directory Structure

- [ ] SKILL.md file exists in skill directory
- [ ] Directory name matches skill name
- [ ] Supporting files in appropriate subdirectories
- [ ] Proper location (not in ~/.cursor/skills-cursor/)
- [ ] Clear folder names with hyphens (not underscores)
- [ ] Each skill is independent

## File References

- [ ] Supporting files referenced explicitly from SKILL.md
- [ ] References include file paths
- [ ] References are one level deep (no complex nesting)
- [ ] Clear indication whether to execute or read scripts
- [ ] All referenced files actually exist

## Workflows

- [ ] Appropriate degrees of freedom for the task type
- [ ] Fragile operations have specific scripts (low freedom)
- [ ] Creative tasks have text guidance (high freedom)
- [ ] Standard patterns have templates (medium freedom)
- [ ] Decision points are explicit
- [ ] Conditional logic is clear ("if X, then Y")

## Feedback Loops (for quality-critical tasks)

- [ ] Validation steps included
- [ ] Clear "check your work" instructions
- [ ] Verification before proceeding to next step
- [ ] Error recovery guidance provided

## Code and Scripts (if applicable)

- [ ] Scripts solve problems rather than punt to the agent
- [ ] Error handling is explicit and helpful
- [ ] No "voodoo constants" (all values justified)
- [ ] Required packages listed in instructions
- [ ] Required packages verified as available
- [ ] Scripts have clear documentation
- [ ] No Windows-style paths (all forward slashes)
- [ ] Validation/verification steps for critical operations
- [ ] Clear usage instructions with examples
- [ ] Expected input/output documented

## Anti-Pattern Check

- [ ] No Windows-style paths (using backslashes)
- [ ] Not providing too many options without a default
- [ ] No time-sensitive information without deprecation handling
- [ ] Consistent terminology (not mixing synonyms)
- [ ] Not using vague skill names
- [ ] Not verbose or teaching common knowledge
- [ ] Not using first or second person in description
- [ ] Not using abstract or placeholder examples

## Terminology and Language

- [ ] Same terms used consistently throughout
- [ ] No mixing of synonyms unnecessarily
- [ ] Technical terms are appropriate for the domain
- [ ] Clear and unambiguous language

## Discovery and Triggering

- [ ] Description contains relevant keywords for discovery
- [ ] Trigger scenarios are explicit
- [ ] Scope is clear (not too broad or too narrow)
- [ ] Related skills don't overlap significantly

## Documentation Quality

- [ ] Purpose is clear from the start
- [ ] Usage instructions are complete
- [ ] Edge cases are addressed
- [ ] Error conditions are documented
- [ ] Prerequisites are listed

## Progressive Disclosure Implementation

- [ ] Essential information in SKILL.md
- [ ] Detailed documentation in separate reference files
- [ ] Large code samples in separate files
- [ ] API documentation externalized
- [ ] Only core workflow in main file

## Validation Scoring

### Critical (Must Pass)
- Valid metadata (name and description)
- Description includes trigger terms
- SKILL.md is readable and well-structured

### Important (Should Pass)
- Under 500 lines
- Uses progressive disclosure
- Consistent terminology
- Concrete examples

### Optional (Nice to Have)
- Additional reference materials
- Comprehensive examples
- Utility scripts with error handling

## Final Assessment Criteria

**Pass**: Meets all critical requirements and most important requirements

**Needs Work**: Missing critical requirements or significant quality issues

**Excellent**: Meets all requirements and demonstrates best practices throughout
