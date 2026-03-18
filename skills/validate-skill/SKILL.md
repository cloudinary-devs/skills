---
name: validate-skill
description: Validates Agent Skills against best practices and specification requirements. Use when checking, reviewing, auditing, or validating a SKILL.md file, or when the user wants to ensure a skill follows best practices.
---

# Validate Skill

This skill validates Agent Skills against the Agent Skills specification and best practices. Use it to ensure skills are well-structured, discoverable, and optimized for token efficiency.

## When to Use

- Reviewing a newly created skill
- Auditing existing skills for quality
- Checking if a skill follows best practices
- Validating before publishing or sharing a skill

## Validation Process

Follow this systematic checklist to validate a skill:

### 1. Metadata Validation

Read the skill's SKILL.md frontmatter and verify:

- [ ] **Name exists** and meets requirements:
  - Max 64 characters
  - Lowercase letters, numbers, and hyphens only
  - Must not start or end with a hyphen
  - Descriptive and specific (not vague like "helper" or "utils")

- [ ] **Description exists** and is effective:
  - Max 1024 characters
  - Non-empty
  - Written in third person (not "I" or "You")
  - Includes WHAT the skill does (specific capabilities)
  - Includes WHEN to use it (trigger terms and scenarios)
  - Specific and includes key terms for discovery

**Example of good description:**
```
Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
```

### 2. Content Quality

- [ ] **Length is appropriate**:
  - SKILL.md body ideally under 500 lines
  - Large references moved to separate files

- [ ] **Concise writing**:
  - No unnecessary explanations of common knowledge
  - Focus on what the agent doesn't already know
  - Each paragraph justifies its token cost
  - No verbose introductions or background

- [ ] **Progressive disclosure**:
  - Essential information in SKILL.md
  - Detailed reference material in separate files
  - References are one level deep (no complex nested chains)

- [ ] **Consistent terminology**:
  - Same terms used throughout
  - No mixing of synonyms (e.g., "API endpoint" vs "URL" vs "route")

- [ ] **Concrete examples**:
  - Examples are specific, not abstract
  - Show actual inputs and outputs
  - Demonstrate the expected format

### 3. Structure Validation

- [ ] **Clear sections**:
  - Instructions are organized logically
  - Workflows have clear, numbered steps
  - Checklists provided for multi-step processes

- [ ] **File references**:
  - Supporting files referenced explicitly
  - References are one level deep from SKILL.md
  - Clear indication whether to execute or read scripts

- [ ] **No time-sensitive information**:
  - No "before August 2025" type statements
  - Deprecated patterns in collapsible sections

### 4. Workflow Design

- [ ] **Appropriate degrees of freedom**:
  - Fragile operations have specific scripts (low freedom)
  - Creative tasks have text guidance (high freedom)
  - Standard patterns have templates (medium freedom)

- [ ] **Feedback loops** (for quality-critical tasks):
  - Validation steps included
  - Clear "check your work" instructions
  - Explicit verification before proceeding

- [ ] **Clear decision points**:
  - Conditional workflows guide through choices
  - "If X, then Y" logic is explicit

### 5. Scripts and Code (if applicable)

- [ ] **Scripts solve problems**:
  - Don't just punt to the agent
  - Handle edge cases
  - Include error handling

- [ ] **Documentation**:
  - Required packages listed
  - Clear usage instructions
  - Expected input/output documented

- [ ] **No anti-patterns**:
  - Forward slashes in paths (not Windows backslashes)
  - No "voodoo constants" (all values justified)
  - Verification steps for critical operations

- [ ] **Package availability**:
  - Required packages verified as available
  - Installation instructions if needed

### 6. Directory Structure

Verify the skill follows proper organization:

```
skill-name/
├── SKILL.md              # Required
├── references/           # Optional - detailed docs
├── scripts/              # Optional - utility scripts
└── assets/               # Optional - templates, schemas
```

- [ ] **Proper location**:
  - Personal: ~/.cursor/skills/skill-name/
  - Project: .cursor/skills/skill-name/
  - NOT in ~/.cursor/skills-cursor/ (reserved for Cursor internal skills)

- [ ] **Clear folder names**:
  - Use hyphens, not underscores
  - Descriptive and specific

### 7. Common Anti-Patterns Check

Flag issues such as:
- Windows-style paths (backslashes)
- Too many options without defaults
- Time-sensitive information
- Inconsistent terminology
- Vague skill names
- Verbose common knowledge explanations
- First/second person language
- Abstract or placeholder examples

For complete list with examples and fixes, see [references/ANTI_PATTERNS.md](references/ANTI_PATTERNS.md)

## Providing Feedback

Structure your validation feedback as:

### ✅ Strengths
List what the skill does well.

### 🔴 Critical Issues
Must-fix issues that violate specification or prevent discovery:
- Missing/invalid metadata
- Description doesn't include trigger terms
- File references broken or nested too deep

### 🟡 Recommended Improvements
Should-fix issues that impact quality:
- SKILL.md over 500 lines
- Verbose content that could be condensed
- Missing progressive disclosure
- Inconsistent terminology

### 🟢 Optional Enhancements
Nice-to-have improvements:
- Additional examples
- More detailed error handling
- Enhanced documentation

## Validation Report Format

Structure your validation feedback with clear severity levels:

- **✅ Strengths**: What the skill does well
- **🔴 Critical Issues**: Must-fix (metadata, broken references, discovery problems)
- **🟡 Recommended Improvements**: Should-fix (verbosity, structure, consistency)
- **🟢 Optional Enhancements**: Nice-to-have additions

For complete report template and examples, see [references/REPORT_TEMPLATE.md](references/REPORT_TEMPLATE.md)

## Quick Validation

For a rapid check, verify these essentials:

1. **Can the agent discover it?** → Check description has trigger terms
2. **Can the agent understand it?** → Check for concise, clear instructions
3. **Is it efficient?** → Check length and progressive disclosure
4. **Will it work?** → Check file references and script documentation

## Additional Resources

### Skill References
- [references/CHECKLIST.md](references/CHECKLIST.md) - Complete validation checklist with all criteria
- [references/ANTI_PATTERNS.md](references/ANTI_PATTERNS.md) - Common anti-patterns with examples and fixes
- [references/REPORT_TEMPLATE.md](references/REPORT_TEMPLATE.md) - Report structure and scoring guidelines

### External Documentation
- [Agent Skills Specification](https://agentskills.io/specification) - Complete specification
