import { tool } from "@opencode-ai/plugin"

const BASE = (process.env.VIKUNJA_URL ?? "https://tickets.home.purplish.blue").replace(/\/$/, "")

function token(): string | null {
  return process.env.VIKUNJA_TOKEN ?? null
}

const NO_TOKEN =
  "Error: VIKUNJA_TOKEN environment variable is not set. Export a Vikunja bot API token (tk_...) as VIKUNJA_TOKEN before starting opencode."

export default tool({
  description: "Create a new project on the Vikunja ticket tracker.",
  args: {
    title: tool.schema.string().describe("Project title"),
    description: tool.schema.string().optional().describe("Project description (Markdown)"),
  },
  async execute(args) {
    if (!token()) return NO_TOKEN

    const body: Record<string, unknown> = { title: args.title }
    if (args.description) body.description = args.description

    const res = await fetch(`${BASE}/api/v2/projects?format=markdown`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token()}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    })
    if (!res.ok) return `Vikunja API error ${res.status}: ${await res.text()}`

    const project = (await res.json()) as { id: number; title: string }
    return `Created project #${project.id} "${project.title}"`
  },
})
