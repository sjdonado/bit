import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["signupModal", "loginModal"]

  openLoginModal() {
    this.loginModalTarget.classList.remove("hidden")
  }

  closeLoginModal() {
    this.loginModalTarget.classList.add("hidden")
  }

  openSignupModal() {
    this.signupModalTarget.classList.remove("hidden") 
  }

  closeSignupModal() {
    this.signupModalTarget.classList.add("hidden") 
  }

  onSignupSuccess() {
    this.closeSignupModal();
  }

  onLoginSuccess() {
    this.closeLoginModal();
  }

  onError(event) {
    const [data, ,] = event.detail

    const usernameError = `Username: ${data.username.join(' ')}`
    const passwordError = `Password: ${data.username.join(' ')}`

    alert(`${usernameError}, ${passwordError}`)
  }
}
