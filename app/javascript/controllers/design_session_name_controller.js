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
    const name = this.element.value

    try {
      await fetch(`/design_sessions/${this.uuidValue}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify({ design_session: { name } })
      })
    } catch (error) {
      console.warn("Failed to save project name", error)
    }
  }
}
