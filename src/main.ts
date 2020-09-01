import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import _ from 'lodash'
import App from './App.vue'
import axios from 'axios'
import BootstrapVue from 'bootstrap-vue'
import router from './router'
import store from './store'
import Vue from 'vue'


Vue.config.productionTip = process.env.VUE_APP_DEBUG.toLowerCase() === 'true'

// Mount packages
Vue.use(BootstrapVue)

// Axios
const apiBaseUrl = process.env.VUE_APP_API_BASE_URL
axios.defaults.withCredentials = true

const axiosErrorHandler = error => {
  const errorStatus = _.get(error, 'response.status')
  if (_.get(Vue.prototype.$currentUser, 'isAuthenticated')) {
    if (errorStatus === 404) {
      router.push({ path: '/404' })
    } else if (errorStatus >= 400) {
      const message = _.get(error, 'response.data.message') || error.message
      console.error(message)
      router.push({
        path: '/error',
        query: {
          m: message
        }
      })
    }
  } else {
    router.push({
      path: '/login',
      query: {
        m: 'Your session has expired'
      }
    })
  }
}

axios.interceptors.response.use(
  response => response.headers['content-type'] === 'application/json' ? response.data : response,
  error => {
    const errorStatus = _.get(error, 'response.status')
    if (_.includes([401, 403], errorStatus)) {
      // Refresh user in case his/her session expired.
      return axios.get(`${apiBaseUrl}/api/user/my_profile`).then(data => {
        Vue.prototype.$currentUser = data
        axiosErrorHandler(error)
        return Promise.reject(error)
      })
    } else {
      axiosErrorHandler(error)
      return Promise.reject(error)
    }
  })

axios.get(`${apiBaseUrl}/api/my/status`).then(response => {
  Vue.prototype.$currentUser = response.data
  Vue.prototype.$currentUser.isLoggedIn = _.get(response.data, 'isLoggedIn', false)

  axios.get(`${apiBaseUrl}/api/config`).then(response => {
    Vue.prototype.$config = response.data
    Vue.prototype.$config.apiBaseUrl = apiBaseUrl
    Vue.prototype.$config.isVueAppDebugMode = _.trim(process.env.VUE_APP_DEBUG).toLowerCase() === 'true'

    new Vue({
      router,
      store,
      render: h => h(App)
    }).$mount('#app')
  })
})
