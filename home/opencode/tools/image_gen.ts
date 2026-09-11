import { tool } from "@opencode-ai/plugin"
import { mkdir, writeFile } from "node:fs/promises"
import path from "node:path"
import { pathToFileURL } from "node:url"

const BASE = "https://route.daze.lol/v1"

export default tool({
  description:
    "Generate an image when the user asks for artwork, an illustration, a graphic, or an image. Saves the result in generated-images/ and attaches it to the response.",
  args: {
    prompt: tool.schema.string().describe("Detailed image generation prompt"),
    model: tool.schema.string().optional().describe("Route image model; defaults to gpt-image-2"),
    size: tool.schema.string().optional().describe("Image size; defaults to 1024x1024"),
    quality: tool.schema.enum(["auto", "low", "medium", "high"]).optional(),
    background: tool.schema.enum(["auto", "opaque", "transparent"]).optional(),
    filename: tool.schema
      .string()
      .regex(/^[A-Za-z0-9][A-Za-z0-9._-]*$/)
      .optional()
      .describe("Output filename without directories; defaults to a timestamped PNG"),
  },
  async execute(args, context) {
    const apiKey = process.env.ROUTE_API_KEY
    if (!apiKey) return "Error: ROUTE_API_KEY is not set. Restart opencode through its configured wrapper."

    const response = await fetch(`${BASE}/images/generations`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: args.model ?? "gpt-image-2",
        prompt: args.prompt,
        n: 1,
        size: args.size ?? "1024x1024",
        quality: args.quality ?? "high",
        background: args.background ?? "transparent",
        output_format: "png",
        response_format: "b64_json",
      }),
      signal: context.abort,
    })
    if (!response.ok) return `Route image API error ${response.status}: ${await response.text()}`

    const payload = (await response.json()) as {
      data?: Array<{ b64_json?: string; url?: string }>
    }
    const image = payload.data?.[0]
    let bytes: Uint8Array
    if (image?.b64_json) {
      bytes = Buffer.from(image.b64_json, "base64")
    } else if (image?.url) {
      const imageResponse = await fetch(image.url, { signal: context.abort })
      if (!imageResponse.ok) return `Generated image download error ${imageResponse.status}`
      bytes = new Uint8Array(await imageResponse.arrayBuffer())
    } else {
      return "Route image API returned no image data."
    }

    const directory = path.join(context.directory, "generated-images")
    const filename = args.filename?.endsWith(".png")
      ? args.filename
      : `${args.filename ?? `image-${Date.now()}`}.png`
    const outputPath = path.join(directory, filename)
    await mkdir(directory, { recursive: true })
    await writeFile(outputPath, bytes)

    return {
      title: `Generated ${filename}`,
      output: `Generated image: ${path.relative(context.directory, outputPath)}`,
      attachments: [
        {
          type: "file",
          mime: "image/png",
          url: pathToFileURL(outputPath).href,
          filename,
        },
      ],
    }
  },
})
