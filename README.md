# Skills

A personal Claude Code skill marketplace. Skills are folders of instructions, scripts, and resources that Claude loads dynamically to improve performance on specialized tasks.

For more information on how skills work, see [agentskills.io](http://agentskills.io).

# Skills

| Skill | Description |
|---|---|
| [mobile-deployer](./skills/mobile-deployer) | Onboard a fresh iOS/Android project with a complete Fastlane deployment pipeline — Match certificates, TestFlight, Google Play |

# Install in Claude Code

Register this repo as a plugin marketplace:

```
/plugin marketplace add onardejesus/skills
```

Then install a skill:

```
/plugin install mobile-deployer@onardejesus-skills
```

# Skill Structure

Each skill is a folder with a `SKILL.md` file:

```markdown
---
name: my-skill-name
description: What this skill does and when to use it
---

# Instructions

[What Claude should do when this skill is active]
```

See [./template](./template) for a starter template.
