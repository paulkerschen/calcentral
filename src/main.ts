import 'bootstrap/dist/css/bootstrap.min.css'
import 'bootstrap-vue/dist/bootstrap-vue.min.css'
import _ from 'lodash'
import App from './App.vue'
import axios from 'axios'
import BootstrapVue from 'bootstrap-vue'
import moment from 'moment-timezone'
import VueMoment from 'vue-moment'
import router from './router'
import store from './store'
import Vue from 'vue'
import { far } from '@fortawesome/free-regular-svg-icons'
import { fas } from '@fortawesome/free-solid-svg-icons'
import { faSpinner } from '@fortawesome/free-solid-svg-icons/faSpinner'
import { faUserSecret } from '@fortawesome/free-solid-svg-icons'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
import { library } from '@fortawesome/fontawesome-svg-core'

library.add(far, fas, faSpinner, faUserSecret)

Vue.config.productionTip = process.env.VUE_APP_DEBUG.toLowerCase() === 'true'
Vue.use(BootstrapVue)
Vue.use(VueMoment, { moment })
Vue.component('fa', FontAwesomeIcon) // eslint-disable-line vue/component-definition-name-casing

const putFocusNextTick = (id, cssSelector) => {
  const callable = () => {
    let el = document.getElementById(id)
    el = el && cssSelector ? el.querySelector(cssSelector) : el
    el && el.focus()
    return !!el
  }
  Vue.prototype.$nextTick(() => {
    let counter = 0
    const job = setInterval(() => (callable() || ++counter > 3) && clearInterval(job), 500)
  })
}

// Mount packages
Vue.prototype.$_ = _
Vue.prototype.$loading = () => store.dispatch('context/loadingStart')
Vue.prototype.$ready = label => store.dispatch('context/loadingComplete', label)
Vue.prototype.$putFocusNextTick = putFocusNextTick

// Axios
const apiBaseUrl = process.env.VUE_APP_API_BASE_URL
axios.defaults.withCredentials = true

const axiosErrorHandler = error => {
  const errorStatus = _.get(error, 'response.status')
  if (_.get(Vue.prototype.$currentUser, 'isLoggedIn')) {
    if (!errorStatus || errorStatus >= 400) {
      const message = _.get(error, 'response.data.error') || _.get(error, 'response.data.message') || error.message
      router.push({
        path: '/error',
        query: {
          m: message
        }
      })
    } else if (errorStatus === 404) {
      router.push({ path: '/404' })
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
  response => response,
  error => {
    const errorStatus = _.get(error, 'response.status')
    if (_.includes([401, 403], errorStatus)) {
      // Refresh user in case his/her session expired.
      return axios.get(`${apiBaseUrl}/api/my/status`).then(response => {
        Vue.prototype.$currentUser = response.data
        const errorUrl = _.get(error, 'response.config.url')
        // Auth errors from the academics API should be handled by individual LTI components.
        if (!(errorUrl && errorUrl.includes('/api/academics'))) {
          axiosErrorHandler(error)
        }
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

    // Set Axios CSRF headers for non-GET requests
    axios.defaults.headers.post['X-CSRF-Token'] = response.data.csrfToken
    axios.defaults.headers.put['X-CSRF-Token'] = response.data.csrfToken
    axios.defaults.headers.delete['X-CSRF-Token'] = response.data.csrfToken

    new Vue({
      router,
      store,
      render: h => h(App)
    }).$mount('#app')
  })
})
