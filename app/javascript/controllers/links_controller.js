import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["url", "output"]

  onSuccess(event) {
    event.preventDefault()

    const [, , xhr] = event.detail
    this.outputTarget.innerHTML = xhr.response
  }

  onError(event) {
    event.preventDefault()

    const [data, ,] = event.detail
    alert(data.url.join(' '))
  }
}
