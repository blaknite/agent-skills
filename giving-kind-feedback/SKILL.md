---
name: giving-kind-feedback
description: "Kind engineering principles for giving feedback. Use when writing code review comments, giving criticism, coaching teammates, or any async communication where tone and empathy matter."
---

# Kind Feedback

Principles for giving kind, honest, effective feedback. Based on Kind Engineering by Evan Smith, Radical Candor by Kim Scott, Give and Take by Adam Grant, and real-world patterns from exemplary code reviewers.

## Kind vs. Nice

**Nice** is polite and agreeable. **Kind** is invested in helping someone grow.

- Nice brings in cake. Kind advocates for your promotion behind the scenes.
- Nice says "good job!" when the meeting went badly. Kind says what went well, what didn't, and how to improve.
- White lies are nice but they don't help people grow.

**Be kind, not just nice.** Meet people where *they* are, not where *you* are.

## The Three Elements of Giving Feedback

Every piece of feedback needs all three:

### 1. Emotion
Take the *listener's* emotions into account, not your own. Set your own feelings aside so the message stays clear. If the feedback is about an emotion they caused, don't still be living in that emotion when you deliver it — it will cloud your message.

### 2. Credibility
Demonstrate expertise and humility. Call out what went well alongside what needs to change. Building credibility over time makes future feedback land better.

### 3. Logic
Show your work. Be specific about why you're giving this feedback and how you reached your conclusion. Clear reasoning lets the recipient check for flaws or fill in missing context.

## Understand the Why, Not Just the How
- Put yourself in the author's shoes. Why did they make this change? Why this approach?
- Assume you're missing something and ask for clarification rather than correction.
- Ask open-ended questions instead of strong statements. Give people the chance to fill in gaps in your understanding.

| Instead of | Try |
|-----------|-----|
| "This is wrong" | "What was the reasoning behind this approach?" |
| "We do it like this" | "Have you considered X? It might handle Y better because..." |
| "You should know better" | "I think there might be an issue with Z here — what do you think?" |

## Own the Confusion
When something is unclear, frame it as *your* experience, not the author's failure. This invites clarification without blame.

| Instead of | Try |
|-----------|-----|
| "This is confusing" | "Upon first read, I was a little confused by this condition" |
| "This is hard to follow" | "It took me a few reads of this method to get it, but I got there in the end" |
| "You need to explain this" | "I wonder if a short doc comment would help here — it took me a moment to see what's happening" |

## Signal Blocking Status
The author needs to know how much weight to give your feedback. Most of the time your tone already does this. When severity genuinely is ambiguous, a short statement or prefix will suffice. Don't restate what the tone or a prefix already conveys.

## Keep It Concise

- Focus on what matters most. Trying to cover everything dilutes the points that really need attention.
- Being concise matters. The longer the feedback, the harder it is to act on.
- If the same theme comes up more than once, name the pattern rather than repeating yourself.

## Match Explanation Depth to Expertise

- Pay attention to what someone has already demonstrated they know. If they got something right elsewhere and slipped up once, that's an oversight, not a gap in understanding.
- When the mistake is clearly an oversight, pointing to where they already got it right is more respectful than re-explaining the concept.
- Deeper explanations belong where the person's work suggests genuine unfamiliarity: new concepts, subtle gotchas, or territory they haven't worked in before.

## Be Direct When It Matters

- Kindness and directness aren't opposites. Being vague about a real problem isn't kind, it's confusing.
- When something is clearly wrong, say so plainly.
- Questions can be teaching tools, but don't use them to hide a problem — name the issue, then ask.

## Don't Make It Personal

- Comment on work and actions, not the person
- We are not defined by our work — a mistake is not a personal failing
- Be specific: specificity shows attention and makes both praise and criticism feel genuine
- Understand individual failure is usually a failure of process, environment, or workflow - focus on fixing the system

## Always Offer a Path Forward

- If you give critical feedback, offer a solution or a first step
- "Your answer was a bit rambly and you missed the chance to convince the team. But it's a good idea — practice your elevator pitch and you'll get it next time."
- The pattern is: honest assessment, acknowledge what's good, clear way to improve
- In code reviews, frame forward paths as questions that invite collaboration: *"Are we sure about `app/contracts/` for these? Possibly `app/kafka/contracts/` might be better and more intention-revealing?"*
- Offer permission to defer: *"Won't block on this, just something to think about."*

## Turn Failure Into Learning
- Every failure is an opportunity to grow
- To promote innovation, people need to feel safe taking risks
- Use the retrospective framework: What went well? What went badly? What should we do differently?

## Advocate for the Next Reader, Not Your Preferences

- Frame suggestions in terms of *future readers*, not personal taste. This depersonalizes the feedback and makes it about the codebase.
- *"People from outside our small portals group are definitely going to look at this line in the future and wonder what's going on."*
- *"A short comment here would make it easier for someone to confidently change this setting in the future."*
- The argument isn't "I want this" — it's "the codebase needs this." That's much harder to take personally.

## Empower, Don't Gatekeep

- Grant the author decision-making autonomy wherever possible.
- *"I'll trust you to decide what you'd like to do now vs after merging."*
- *"You should feel empowered to make the call here."*
- *"I'm more than happy to trust you with this particular call!"*
- Use "Request Changes" as a conversation opener, not a verdict: *"I'm just dropping a 'request changes' status here to at least ensure we get to have a conversation about this."*
- Disclose conflicts of interest transparently so the author can weigh your feedback fairly.

## Be Inclusive

- Be aware of people's backgrounds, experiences, and communication preferences
- Watch for people who don't speak up in meetings — find ways to give them a voice
- Let people express themselves in whatever format works for them
- Kindness is not "meet me halfway" — it's meeting people where *they* are
