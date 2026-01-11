import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    uuid: String
  }

  async save() {
    const token = document.querySelector("meta[name='csrf-token']")?.content
    const assemblyDefinitionId = this.element.value

    try {
      await fetch(`/design_sessions/${this.uuidValue}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": token
        },
        credentials: "same-origin",
        body: JSON.stringify({ design_session: { assembly_definition_id: assemblyDefinitionId || null } })
      })
      window.location.reload()
    } catch (error) {
      console.warn("Failed to save assembly", error)
    }
  }
}
