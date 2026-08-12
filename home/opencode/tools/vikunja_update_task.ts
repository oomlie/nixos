import { tool } from "@opencode-ai/plugin"

const BASE = (process.env.VIKUNJA_URL ?? "https://tickets.home.purplish.blue").replace(/\/$/, "")

function token(): string | null {
  return process.env.VIKUNJA_TOKEN ?? null
}

const NO_TOKEN =
  "Error: VIKUNJA_TOKEN environment variable is not set. Export a Vikunja bot API token (tk_...) as VIKUNJA_TOKEN before starting opencode."

export default tool({
  description:
    "Update a Vikunja task: mark done/undone, change title, description, priority, or due date. Only provided fields are changed.",
  args: {
    task_id: tool.schema.number().describe("Task id (the numeric id, not the #identifier)"),
    done: tool.schema.boolean().optional().describe("Mark the task done or not done"),
    title: tool.schema.string().optional().describe("New task title"),
    description: tool.schema.string().optional().describe("New task description (Markdown)"),
    priority: tool.schema.number().min(0).max(5).optional().describe("Priority 0 (unset) to 5 (urgent)"),
    due_date: tool.schema
      .string()
      .optional()
      .describe("Due date in RFC3339 format, e.g. 2026-07-30T00:00:00Z"),
  },
  async execute(args) {
    if (!token()) return NO_TOKEN

    const body: Record<string, unknown> = {}
    if (args.done !== undefined) body.done = args.done
    if (args.title !== undefined) body.title = args.title
    if (args.description !== undefined) body.description = args.description
    if (args.priority !== undefined) body.priority = args.priority
    if (args.due_date !== undefined) body.due_date = args.due_date
    if (Object.keys(body).length === 0) return "Nothing to update: provide at least one field."

    const res = await fetch(`${BASE}/api/v2/tasks/${args.task_id}?format=markdown`, {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${token()}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    })
    if (!res.ok) return `Vikunja API error ${res.status}: ${await res.text()}`

    const task = (await res.json()) as { id: number; identifier: string; title: string; done: boolean }
    return `Updated task ${task.identifier} [id:${task.id}] "${task.title}" (done: ${task.done})`
  },
})
