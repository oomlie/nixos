const DEFAULT_BASE_URL = "https://route.daze.lol/v1"
const TIMEOUT_MS = 5000

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
          models[id] = { name: id, reasoning: true }
        }
      }
    } catch {
      return
    }
  },
})
