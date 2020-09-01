import App from './App.vue'
import router from './router'
import store from './store'
import Vue from 'vue'

const isDebugMode = process.env.VUE_APP_DEBUG.toLowerCase() === 'true'

Vue.config.productionTip = isDebugMode

new Vue({
  router,
  store,
  render: h => h(App)
}).$mount('#app')
