import { Controller } from "stimulus"

export default class extends Controller {
  onError(event) {
    const [data, ,] = event.detail
    
    const usernameError = `Username: ${data.username.join(' ')}`
    const passwordError = `Password: ${data.username.join(' ')}`

    alert(`${usernameError}, ${passwordError}`)
  }
}
