import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["url", "output", "userLinks"]

  initialize() {
    this.loggedIn = Boolean(document.querySelector('meta[name="logged-in"]').getAttribute('content') === 'true')
  }

  onCreateLinkSuccess(event) {
    const [, , xhr] = event.detail
    this.outputTarget.innerHTML = xhr.response
    if (this.loggedIn && !this.userLinksTarget.innerHTML.includes(xhr.response)) {
      this.userLinksTarget.innerHTML = xhr.response + this.userLinksTarget.innerHTML
    }
  }

  onCreateLinkError(event) {
    const [data, ,] = event.detail
    const urlError = `Url: ${data.url.join(' ')}`
    alert(urlError)
  }
}
