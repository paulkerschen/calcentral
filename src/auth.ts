import Vue from 'vue'

const goToLogin = (to: any, next: any) => {
  next({
    path: '/login',
    query: {
      error: to.query.error,
      redirect: to.name === 'toolbox' ? undefined : to.fullPath
    }
  })
}

export default {
  requiresAdmin: (to: any, from: any, next: any) => {
    const currentUser = Vue.prototype.$currentUser
    if (currentUser.isLoggedIn && currentUser.isSuperuser) {
      next()
    } else {
      goToLogin(to, next)
    }
  }
}
