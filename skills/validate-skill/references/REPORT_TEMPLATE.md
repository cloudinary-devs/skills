# Skill Validation Report Template

Use this template structure when providing validation feedback to users.

## Report Structure

```markdown
# Skill Validation Report: [skill-name]

## Summary
[One paragraph overview of the skill and validation results]

## Metadata Review
- **Name**: [valid/issues with specifics]
- **Description**: [valid/issues with specifics]

## Content Quality
- **Length**: [X lines - within/exceeds guidelines]
- **Conciseness**: [good/needs improvement with specifics]
- **Progressive disclosure**: [used appropriately/not used/details]

## Structure
- **Organization**: [clear/needs improvement]
- **File references**: [appropriate/issues]
- **Workflows**: [clear/needs improvement]

---

## ✅ Strengths
- [Strength 1]
- [Strength 2]
- [Strength 3]

## 🔴 Critical Issues
Must-fix issues that violate specification or prevent discovery:
- [Critical issue 1 with specific location and fix]
- [Critical issue 2 with specific location and fix]

## 🟡 Recommended Improvements
Should-fix issues that impact quality:
- [Improvement 1 with specific suggestion]
- [Improvement 2 with specific suggestion]

## 🟢 Optional Enhancements
Nice-to-have improvements:
- [Enhancement 1]
- [Enhancement 2]

---

## Overall Assessment
**[Pass/Needs Work/Excellent]**

[Brief summary of readiness and next steps]
```

## Example Report

```markdown
# Skill Validation Report: pdf-processor

## Summary
PDF processing skill that handles text extraction, form filling, and document merging. Generally well-structured with good examples but has some verbosity issues.

## Metadata Review
- **Name**: ✅ Valid - descriptive and follows naming conventions
- **Description**: ✅ Good - includes capabilities and trigger terms ("PDF", "forms", "extraction")

## Content Quality
- **Length**: 380 lines - within guidelines
- **Conciseness**: Needs improvement - contains common knowledge explanations
- **Progressive disclosure**: ✅ Used effectively with 3 reference files

## Structure
- **Organization**: ✅ Clear sections with logical flow
- **File references**: ✅ All exist and properly referenced
- **Workflows**: ✅ Clear numbered steps

---

## ✅ Strengths
- Excellent use of progressive disclosure
- Concrete examples with actual file paths
- Clear workflows with numbered steps
- Good error handling documentation

## 🔴 Critical Issues
None - skill meets all specification requirements.

## 🟡 Recommended Improvements
- Lines 45-60: Remove explanation of "what is a PDF" (common knowledge)
- Line 89: Consolidate three similar examples into one
- Consider moving installation instructions to references/SETUP.md

## 🟢 Optional Enhancements
- Add more advanced merge examples
- Include performance tips for large documents
- Add troubleshooting section for common errors

---

## Overall Assessment
**Pass** - Skill is ready for use with minor improvements recommended for optimal token efficiency.
```

## Scoring Guidelines

### Critical Issues (Must Fix)
- Invalid or missing metadata
- Description lacks trigger terms
- Broken file references
- First/second person in description
- No clear instructions

### Recommended Improvements (Should Fix)
- Over 500 lines without progressive disclosure
- Verbose explanations of common knowledge
- Inconsistent terminology
- Abstract/placeholder examples
- File nesting too deep

### Optional Enhancements (Nice to Have)
- Additional examples
- More comprehensive error handling
- Enhanced documentation
- Performance optimization tips
- Advanced usage patterns
