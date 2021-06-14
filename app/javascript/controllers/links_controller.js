import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["url", "output"]

  onSuccess(event) {
    const [, , xhr] = event.detail
    this.outputTarget.innerHTML = xhr.response
  }

  onError(event) {
    const [data, ,] = event.detail

    const urlError = `Url: ${data.url.join(' ')}`

    alert(urlError)
  }
}
