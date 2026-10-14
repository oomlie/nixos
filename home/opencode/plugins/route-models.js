const DEFAULT_BASE_URL = "https://route.daze.lol/v1"
const TIMEOUT_MS = 5000

// route.daze.lol's /v1/models only returns `id` and `owned_by`, so display
// names are derived from the id. `owned_by` is unreliable (Claude/Qwen models
// report as "anthropic"), so it is not used for display. Ids already declared
// in opencode config are left untouched, so any model can be overridden with a
// nicer name, real limits, or attachments under provider.route.models.

const BRANDS = {
  ai: "AI",
  glm: "GLM",
  gpt: "GPT",
  oss: "OSS",
  tts: "TTS",
  vl: "VL",
  deepseek: "DeepSeek",
}

const SMALL_WORDS = new Set(["and", "for", "of", "the", "to", "in", "on", "with"])

const isNumeric = (word) => /^\d+(\.\d+)?$/.test(word)
const isSnapshot = (token) =>
  /^20\d{6}$/.test(token) || /^(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])$/.test(token)
const isUnit = (token) => /^[\d.]+[a-z]$/.test(token)

export const prettyName = (id) => {
  const words = []
  for (const token of id.split(/[-_/]+/).filter(Boolean)) {
    if (isSnapshot(token)) continue
    if (words.length && isNumeric(token) && isNumeric(words.at(-1))) {
      words[words.length - 1] += `.${token}`
      continue
    }
    const brand = BRANDS[token.toLowerCase()]
    if (brand) {
      words.push(brand)
    } else if (isUnit(token)) {
      words.push(token.slice(0, -1) + token.slice(-1).toUpperCase())
    } else if (words.length && SMALL_WORDS.has(token.toLowerCase())) {
      words.push(token.toLowerCase())
    } else {
      words.push(token.charAt(0).toUpperCase() + token.slice(1))
    }
  }
  return words.join(" ")
}

export const RouteModelDiscovery = async () => ({
  config: async (config) => {
    try {
      const provider = config?.provider?.route
      if (!provider) return

      const baseURL = (provider.options?.baseURL ?? DEFAULT_BASE_URL).replace(/\/+$/, "")
      const apiKey = process.env.ROUTE_API_KEY

      const response = await fetch(`${baseURL}/models`, {
        headers: apiKey ? { authorization: `Bearer ${apiKey}` } : {},
        signal: AbortSignal.timeout(TIMEOUT_MS),
      })
      if (!response.ok) return

      const payload = await response.json()
      const entries = Array.isArray(payload) ? payload : payload?.data
      if (!Array.isArray(entries)) return

      const models = (provider.models ??= {})
      for (const entry of entries) {
        const id = entry?.id
        if (typeof id === "string" && !(id in models)) {
          models[id] = { name: prettyName(id), reasoning: true }
        }
      }
    } catch {
      return
    }
  },
})

if (import.meta.main) {
  const { strict: assert } = await import("node:assert")
  assert.equal(prettyName("gpt-5.6-luna"), "GPT 5.6 Luna")
  assert.equal(prettyName("claude-opus-4-7"), "Claude Opus 4.7")
  assert.equal(prettyName("claude-3-5-haiku-20241022"), "Claude 3.5 Haiku")
  assert.equal(prettyName("gemini-3.1-flash-lite"), "Gemini 3.1 Flash Lite")
  assert.equal(prettyName("kimi-for-coding"), "Kimi for Coding")
  assert.equal(prettyName("gpt-oss-120b-medium"), "GPT OSS 120B Medium")
  console.log("route-models: prettyName self-test passed")
}
