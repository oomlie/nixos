import { tool } from "@opencode-ai/plugin"

const BASE = (process.env.VIKUNJA_URL ?? "https://tickets.home.purplish.blue").replace(/\/$/, "")

function token(): string | null {
  return process.env.VIKUNJA_TOKEN ?? null
}

const NO_TOKEN =
  "Error: VIKUNJA_TOKEN environment variable is not set. Export a Vikunja bot API token (tk_...) as VIKUNJA_TOKEN before starting opencode."

export default tool({
  description: "Create a task in a Vikunja project, optionally with a description, due date, and assignees.",
  args: {
    project_id: tool.schema.number().describe("Project id (from vikunja_projects)"),
    title: tool.schema.string().describe("Task title"),
    description: tool.schema.string().optional().describe("Task description (Markdown)"),
    due_date: tool.schema
      .string()
      .optional()
      .describe("Due date in RFC3339 format, e.g. 2026-07-30T00:00:00Z"),
    assignee_ids: tool.schema
      .array(tool.schema.number())
      .optional()
      .describe("Vikunja user ids to assign to the task"),
  },
  async execute(args) {
    if (!token()) return NO_TOKEN
    const headers = {
      Authorization: `Bearer ${token()}`,
      "Content-Type": "application/json",
    }

    const body: Record<string, unknown> = { title: args.title }
    if (args.description) body.description = args.description
    if (args.due_date) body.due_date = args.due_date

    const res = await fetch(`${BASE}/api/v2/projects/${args.project_id}/tasks?format=markdown`, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
    })
    if (!res.ok) return `Vikunja API error ${res.status}: ${await res.text()}`

    const task = (await res.json()) as { id: number; identifier: string; title: string }

    const failures: string[] = []
    for (const uid of args.assignee_ids ?? []) {
      const r = await fetch(`${BASE}/api/v2/tasks/${task.id}/assignees`, {
        method: "POST",
        headers,
        body: JSON.stringify({ user_id: uid }),
      })
      if (!r.ok) failures.push(`assignee ${uid}: ${r.status} ${await r.text()}`)
    }

    return (
      `Created task ${task.identifier} [id:${task.id}] "${task.title}" in project ${args.project_id}` +
      (failures.length ? `\nFailed to add assignees:\n${failures.join("\n")}` : "")
    )
  },
})
