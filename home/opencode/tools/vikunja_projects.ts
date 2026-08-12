import { tool } from "@opencode-ai/plugin"

const BASE = (process.env.VIKUNJA_URL ?? "https://tickets.home.purplish.blue").replace(/\/$/, "")

function token(): string | null {
  return process.env.VIKUNJA_TOKEN ?? null
}

const NO_TOKEN =
  "Error: VIKUNJA_TOKEN environment variable is not set. Export a Vikunja bot API token (tk_...) as VIKUNJA_TOKEN before starting opencode."

export default tool({
  description:
    "List projects on the Vikunja ticket tracker that the bot has access to. Returns project id, title, and description for each.",
  args: {},
  async execute() {
    if (!token()) return NO_TOKEN

    const res = await fetch(`${BASE}/api/v2/projects?format=markdown`, {
      headers: { Authorization: `Bearer ${token()}` },
    })
    if (!res.ok) return `Vikunja API error ${res.status}: ${await res.text()}`

    const data = (await res.json()) as {
      items: { id: number; title: string; description?: string; is_archived: boolean }[]
    }
    if (!data.items?.length) return "No projects found. Share a project with the bot user first."

    return data.items
      .map(
        (p) =>
          `#${p.id} ${p.title}${p.is_archived ? " (archived)" : ""}${p.description ? `\n   ${p.description}` : ""}`,
      )
      .join("\n")
  },
})
