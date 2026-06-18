import { Controller } from "@hotwired/stimulus"

// Switches between encoding/language panels.
// Usage:
//   <div data-controller="tabs">
//     <button data-action="tabs#select" data-tabs-index-param="0" data-tabs-target="tab">Hex</button>
//     ...
//     <div data-tabs-target="panel">...</div>
//     <div data-tabs-target="panel" hidden>...</div>
//   </div>
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.activate(0)
  }

  select(event) {
    this.activate(event.params.index)
  }

  activate(index) {
    this.panelTargets.forEach((panel, i) => { panel.hidden = i !== index })
    this.tabTargets.forEach((tab, i) => { tab.classList.toggle("tab-active", i === index) })
  }
}
