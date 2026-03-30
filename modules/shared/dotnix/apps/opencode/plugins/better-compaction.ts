import type { Plugin } from "@opencode-ai/plugin"

export const BetterCompactionPlugin: Plugin = async (ctx) => {
  return {
    "experimental.session.compacting": async (input, output) => {
      output.prompt = `You are compacting a conversation to allow it to continue in a new context window. Your job is to produce a continuation prompt that preserves ALL information needed to seamlessly resume the work.

CRITICAL RULES:
1. NEVER generalize or summarize away specific details. Keep exact names, paths, values, error messages, flag names, config keys, URLs, and version numbers.
2. If the user pasted external content (conversation logs, error output, code snippets, config files), reproduce the KEY PARTS verbatim.
3. Preserve ALL user-stated constraints, preferences, and instructions.
4. Preserve the investigation/debugging state: what hypotheses were tested, what was ruled out with what evidence.
5. Preserve emotional context and communication style preferences.

Use this template:

---

## Goal
[Specific goal(s)]

## Instructions
- [User instructions, behavioral constraints, communication preferences]

## Discoveries
[Exact technical details: config values, paths, flag names, versions, what was tried and what happened]

## User-Pasted Content
[Verbatim key parts of any content the user pasted]

## Accomplished

### Completed
[Specific completed work]

### Not Solved
[Unsolved items with investigation state]

### Next Steps
[Planned next actions]

## Relevant files / directories
[Files read/modified/created, with key external references]

---`
    },
  }
}
