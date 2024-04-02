import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]
  static values = { closeOnClick: { type: Boolean, default: true } }

  toggleMenu = (e) => {
    this.menuTarget.classList.contains("hidden") ? this.showMenu() : this.hideMenu();
  }

  showMenu = () => {
    setTimeout(() => {
      // Registering the listener asynchronously prevents event from closing the menu immediately
      document.addEventListener("click", this.onDocumentClick);
    }, 0)

    this.menuTarget.classList.remove("hidden");
  }

  hideMenu = () => {
    document.removeEventListener("click", this.onDocumentClick);
    this.menuTarget.classList.add("hidden");
  }

  disconnect = () => {
    this.hideMenu();
  }

  onDocumentClick = (e) => {
    if (this.element.contains(e.target) && !this.closeOnClickValue ) {
      // user has clicked inside of the dropdown
      e.stopPropagation();
      return;
    }

    this.hideMenu();
  }
}
