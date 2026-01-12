import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    uuid: String,
    delay: { type: Number, default: 400 }
  }

  connect() {
    this.timeout = null
  }

  queueSave() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.save()
    }, this.delayValue)
  }

  async save() {
    const token = document.querySelector("meta[name='csrf-token']")?.content
    const paramsSnapshot = this.collectParams()

    try {
      const response = await fetch(`/design_sessions/${this.uuidValue}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": token
        },
        credentials: "same-origin",
        body: JSON.stringify({ design_session: { params_snapshot: paramsSnapshot } })
      })
      if (!response.ok) throw new Error("Failed to save params")

      const stamp = Date.now().toString()
      this.refreshPreviewAssets(stamp)
      window.dispatchEvent(new CustomEvent("design-session-params:updated", { detail: { stamp } }))
    } catch (error) {
      console.warn("Failed to save params", error)
    }
  }

  collectParams() {
    const params = {}
    const multiselect = {}

    const inputs = this.element.querySelectorAll("[data-param-key]")
    inputs.forEach((input) => {
      const key = input.dataset.paramKey
      const type = input.dataset.paramType

      if (type === "multiselect") {
        if (!multiselect[key]) multiselect[key] = []
        if (input.checked) multiselect[key].push(input.value)
        return
      }

      if (type === "checkbox") {
        params[key] = input.checked
        return
      }

      if (type === "number") {
        const value = input.value.trim()
        params[key] = value === "" ? null : Number(value)
        return
      }

      params[key] = input.value
    })

    return { ...params, ...multiselect }
  }

  refreshPreviewAssets(stamp) {
    const previewLink = document.querySelector("[data-preview-svg-link]")
    if (previewLink) {
      previewLink.href = this.withCacheBuster(previewLink.href, stamp)
    }

    const panelImages = document.querySelectorAll("[data-panel-preview]")
    panelImages.forEach((img) => {
      img.src = this.withCacheBuster(img.src, stamp)
    })
  }

  withCacheBuster(url, stamp) {
    try {
      const parsed = new URL(url, window.location.origin)
      parsed.searchParams.set("ts", stamp)
      return parsed.toString()
    } catch (error) {
      return url
    }
  }
}
