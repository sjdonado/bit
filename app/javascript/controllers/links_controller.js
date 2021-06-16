import { Controller } from "stimulus"
import Turbolinks from "turbolinks"

export default class extends Controller {
  static targets = ["url", "output", "userLinks"]

  initialize() {
    this.lastLink = null
    this.sessionUsername = localStorage.getItem("session-username")
  }

  onCreateLinkSuccess(event) {
    const [, , xhr] = event.detail

    this.outputTarget.innerHTML = xhr.response
    
    if (this.sessionUsername && this.lastLink && this.lastLink.includes(this.sessionUsername)
        && !this.userLinksTarget.innerHTML.includes(this.lastLink)) {
      this.userLinksTarget.innerHTML = this.lastLink + this.userLinksTarget.innerHTML
    }

    this.lastLink = xhr.response
  }

  onCreateLinkError(event) {
    const [data, ,] = event.detail
    const urlError = `Url: ${data.url.join(' ')}`
    alert(urlError)
  }

  async updateLinkCounter(counterElem, slug) {
    const clickCounter = await fetch(`links/${slug}/counter`, {
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      }
    }).then((res) => res.json());

    if (clickCounter) {
      counterElem.innerText = clickCounter
    }
  }

  openLink(event) {
    const counterElem = event.target.parentElement.parentElement.parentElement.getElementsByClassName("counter")[0]
    const link = event.target.innerText

    let visibilitychange = 0
    const visibilitychangeListener = () => {
      if(visibilitychange > 0) {
        document.removeEventListener("visibilitychange", visibilitychangeListener)
        this.updateLinkCounter(counterElem, link.substring(link.lastIndexOf('/') + 1))
        return
      }
      visibilitychange += 1
    }
    document.addEventListener("visibilitychange", visibilitychangeListener)

    window.open(link, "_blank")
  }
}
