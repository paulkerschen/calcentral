import Vue from 'vue'
import axios from 'axios'

export default {
  apiBaseUrl: () => Vue.prototype.$config.apiBaseUrl,
  get: path => axios.get(`${Vue.prototype.$config.apiBaseUrl}${path}`).then(response => response.data),
  post: (path, data={}) => axios.post(`${Vue.prototype.$config.apiBaseUrl}${path}`, data).then(response => response.data)
}
