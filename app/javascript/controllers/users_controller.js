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
    this.closeLoginModal()
    this.signupModalTarget.classList.remove("hidden") 
  }

  closeSignupModal() {
    this.signupModalTarget.classList.add("hidden") 
  }

  onSignupSuccess() {
    this.closeSignupModal();
    Turbolinks.visit('/')
  }

  onLoginSuccess() {
    this.closeLoginModal();
    Turbolinks.visit('/')
  }

  onError(event) {
    const [data, ,] = event.detail

    const errors = []

    if (data.username) {
      errors.push(`Username: ${data.username.join(' ')}`)
    }

    if (data.password) {
      errors.push(`Password: ${data.password.join(' ')}`)
    }

    alert(errors.join(','))
  }

  confirmLogout(event) {
    if (!window.confirm("Do you really want to leave?")) {
      event.stopPropagation()
      return
    }
  }

  onSuccessLogout() {
    Turbolinks.visit('/')
  }
}
