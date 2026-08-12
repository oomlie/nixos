import { tool } from "@opencode-ai/plugin"

const BASE = (process.env.VIKUNJA_URL ?? "https://tickets.home.purplish.blue").replace(/\/$/, "")

function token(): string | null {
  return process.env.VIKUNJA_TOKEN ?? null
}

const NO_TOKEN =
  "Error: VIKUNJA_TOKEN environment variable is not set. Export a Vikunja bot API token (tk_...) as VIKUNJA_TOKEN before starting opencode."

export default tool({
  description: "Add a comment to a Vikunja task.",
  args: {
    task_id: tool.schema.number().describe("Task id (the numeric id, not the #identifier)"),
    comment: tool.schema.string().describe("Comment text (Markdown)"),
  },
  async execute(args) {
    if (!token()) return NO_TOKEN

    const res = await fetch(`${BASE}/api/v2/tasks/${args.task_id}/comments?format=markdown`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token()}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ comment: args.comment }),
    })
    if (!res.ok) return `Vikunja API error ${res.status}: ${await res.text()}`

    return `Comment added to task id ${args.task_id}`
  },
})
