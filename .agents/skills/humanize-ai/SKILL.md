---
name: humanize-ai
description: Enforces authentic human technical writing by eliminating AI cliches, buzzwords, and synthetic filler across documentation, READMEs, and technical blog posts.
---

# Humanize AI Technical Writing

Use this skill when drafting documentation, READMEs, changelogs, or hackathon writeups to ensure the text reads like an authentic, skilled software engineer rather than an AI chatbot.

## Core Rules

1. **Delete the AI Vocabulary Blacklist**:
   - Never use: *"delve"*, *"dive deep"*, *"testament"*, *"tapestry"*, *"in an era where"*, *"in the fast-paced world"*, *"beacon"*, *"orchestration of"*, *"seamlessly"*, *"robust"*, *"supercharge"*, *"elevate"*, *"not X, just Y"*, *"it is important to note"*, *"look no further"*.
   - Replace with plain, literal language: explain what the code actually does (ports, HTTP methods, latency, dependencies).

2. **Vary Sentence Rhythm & Cut Padding**:
   - Avoid monotonous Subject-Verb-Object structures.
   - Mix short, punchy statements with clear explanations.
   - Eliminate filler openings (*"In order to run this..."* -> *"To run this..."*).

3. **Specificity & Receipts Beat Adjectives**:
   - Instead of *"A lightning-fast local inference engine"*, write: *"Runs local Q4_K_M GGUF inference on an RTX 4050 6GB via llama.cpp at ~45 tok/s."*
   - Instead of *"Effortless setup"*, write: *"Installs in under a second using `uv sync`."*

4. **Real Pain Points & Direct Voice**:
   - Write from the perspective of a developer who built the tool to solve an actual problem.
   - Be honest about trade-offs, constraints, and architecture choices.
   - Avoid cheerleading or corporate marketing speak.
