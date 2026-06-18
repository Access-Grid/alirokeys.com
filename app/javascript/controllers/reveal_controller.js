import { Controller } from "@hotwired/stimulus"

// Toggles a blur/select-none mask over sensitive content (e.g. a one-time secret).
// Usage:
//   <div data-controller="reveal">
//     <code data-reveal-target="content" class="blur-sm select-none">secret</code>
//     <button data-action="reveal#toggle"><span data-reveal-target="label">Reveal</span></button>
//   </div>
export default class extends Controller {
  static targets = ["content", "label"]

  connect() {
    this.revealed = false
  }

  toggle(event) {
    event.preventDefault()
    this.revealed = !this.revealed
    this.contentTargets.forEach((el) => {
      el.classList.toggle("blur-sm", !this.revealed)
      el.classList.toggle("select-none", !this.revealed)
    })
    if (this.hasLabelTarget) this.labelTarget.textContent = this.revealed ? "Hide" : "Reveal"
  }
}
