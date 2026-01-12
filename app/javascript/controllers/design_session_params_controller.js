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
      await fetch(`/design_sessions/${this.uuidValue}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": token
        },
        credentials: "same-origin",
        body: JSON.stringify({ design_session: { params_snapshot: paramsSnapshot } })
      })
      window.dispatchEvent(new CustomEvent("design-session-params:updated"))
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
}
