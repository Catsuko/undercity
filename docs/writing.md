# Writing Guide

Style conventions for documentation in this project.

## Structure

- Use `##` for major sections, `###` for subsections. Avoid `####` and deeper.
- Section titles are short noun phrases or imperative verbs, not full sentences.
- Open each major section with a one-sentence summary before any sub-headers or bullets.
- Use headers alone to separate sections — no `---` horizontal dividers.

## Prose

- Lead with the subject and action. Put explanatory clauses in bullets, not mid-sentence.
- Prefer active and imperative voice: "Declare connections once" not "Connections are declared once."
- Don't restate the previous sentence. If the next sentence already says it, cut the first.
- Keep analogies and informal comparisons out of reference tables and rule lists.

## Lists and tables

- Use bullets for any enumerable facts, options, or requirements — not dense prose sentences.
- Use tables for structured reference data with clear column semantics. Keep column headers short (1–3 words).
- Don't use a table where a two-column key-value list would read more clearly as bullets.

## Code

- Introduce code blocks with a colon at the end of the preceding sentence, no blank line between.
- Use inline `code` for type names, function names, file paths, and field values referenced in prose.
- Don't use code blocks for things that read clearly as inline references.

## Length

- Move large reference tables (e.g. full block listings) to a dedicated file and link to it. Keep guides scannable.
- If you can say it in one sentence, don't use three.
