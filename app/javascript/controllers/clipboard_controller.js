import { Controller } from "@hotwired/stimulus"

// Copies a value to the clipboard and briefly confirms.
// Usage:
//   <div data-controller="clipboard" data-clipboard-text-value="...">
//     <button data-action="clipboard#copy">
//       <span data-clipboard-target="label">Copy</span>
//     </button>
//   </div>
export default class extends Controller {
  static values = { text: String }
  static targets = ["label", "copyIcon", "checkIcon"]

  copy(event) {
    event.preventDefault()
    const text = this.textValue
    const done = () => this.flash()
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(done).catch(() => this.fallback(text, done))
    } else {
      this.fallback(text, done)
    }
  }

  fallback(text, done) {
    const ta = document.createElement("textarea")
    ta.value = text
    ta.style.position = "fixed"
    ta.style.opacity = "0"
    document.body.appendChild(ta)
    ta.select()
    try { document.execCommand("copy") } catch (_) {}
    document.body.removeChild(ta)
    done()
  }

  flash() {
    if (this.hasCopyIconTarget) this.copyIconTarget.classList.add("hidden")
    if (this.hasCheckIconTarget) this.checkIconTarget.classList.remove("hidden")
    if (this.hasLabelTarget) {
      if (this.original === undefined) this.original = this.labelTarget.textContent
      this.labelTarget.textContent = "Copied!"
      this.labelTarget.classList.add("text-emerald-600")
    }
    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      if (this.hasCopyIconTarget) this.copyIconTarget.classList.remove("hidden")
      if (this.hasCheckIconTarget) this.checkIconTarget.classList.add("hidden")
      if (this.hasLabelTarget && this.original !== undefined) {
        this.labelTarget.textContent = this.original
        this.labelTarget.classList.remove("text-emerald-600")
      }
    }, 1500)
  }
}
