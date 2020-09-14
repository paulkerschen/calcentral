import Vue from 'vue'

const goToLogin = (to: any, next: any) => {
  next({
    path: '/login',
    query: {
      error: to.query.error,
      redirect: to.fullPath
    }
  })
}

export default {
  requiresAdmin: (to: any, from: any, next: any) => {
    const currentUser = Vue.prototype.$currentUser
    if (currentUser.isLoggedIn) {
      next()
    } else {
      goToLogin(to, next)
    }
  }
}
