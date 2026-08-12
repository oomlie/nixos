import { tool } from "@opencode-ai/plugin"

const BASE = (process.env.VIKUNJA_URL ?? "https://tickets.home.purplish.blue").replace(/\/$/, "")

function token(): string | null {
  return process.env.VIKUNJA_TOKEN ?? null
}

const NO_TOKEN =
  "Error: VIKUNJA_TOKEN environment variable is not set. Export a Vikunja bot API token (tk_...) as VIKUNJA_TOKEN before starting opencode."

const ZERO_DATE = "0001-01-01T00:00:00Z"

export default tool({
  description:
    "List tasks in a Vikunja project. Returns task id, identifier, title, done status, due date, and assignees.",
  args: {
    project_id: tool.schema.number().describe("Project id (from vikunja_projects)"),
    include_done: tool.schema
      .boolean()
      .optional()
      .describe("Include completed tasks (default false)"),
  },
  async execute(args) {
    if (!token()) return NO_TOKEN

    const res = await fetch(`${BASE}/api/v2/projects/${args.project_id}/tasks?format=markdown`, {
      headers: { Authorization: `Bearer ${token()}` },
    })
    if (!res.ok) return `Vikunja API error ${res.status}: ${await res.text()}`

    const data = (await res.json()) as {
      items: {
        id: number
        identifier: string
        title: string
        done: boolean
        due_date: string
        assignees: { username: string }[] | null
      }[]
    }

    const tasks = (data.items ?? []).filter((t) => args.include_done || !t.done)
    if (!tasks.length) return "No tasks found."

    return tasks
      .map((t) => {
        const due = t.due_date && t.due_date !== ZERO_DATE ? ` due:${t.due_date.slice(0, 10)}` : ""
        const who = t.assignees?.length ? ` @${t.assignees.map((a) => a.username).join(", @")}` : ""
        return `${t.identifier} [id:${t.id}] ${t.done ? "[x]" : "[ ]"} ${t.title}${due}${who}`
      })
      .join("\n")
  },
})
