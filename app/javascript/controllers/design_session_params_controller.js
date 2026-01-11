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
    } catch (error) {
      console.warn("Failed to save params", error)
    }
  }

  collectParams() {
    const numberValue = (name) => {
      const input = this.element.querySelector(`[name="${name}"]`)
      if (!input) return null
      const value = input.value.trim()
      return value === "" ? null : Number(value)
    }

    const zipperLocations = Array.from(
      this.element.querySelectorAll('input[name="zipper_locations[]"]:checked')
    ).map((input) => input.value)

    const pocketEnabled = this.element.querySelector('input[name="pocket_enabled"]')?.checked
    const pocketPlacement = this.element.querySelector('[name="pocket_placement"]')?.value

    return {
      units: "in",
      height: numberValue("height"),
      width: numberValue("width"),
      depth: numberValue("depth"),
      seam_allowance: numberValue("seam_allowance"),
      zipper_locations: zipperLocations,
      zipper_style: this.element.querySelector('[name="zipper_style"]')?.value,
      pocket: {
        enabled: Boolean(pocketEnabled),
        placement: pocketPlacement || "center"
      }
    }
  }
}
