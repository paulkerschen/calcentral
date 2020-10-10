import _ from 'lodash'
import axios from 'axios'
import Vue from 'vue'

export default {
  apiBaseUrl: () => Vue.prototype.$config.apiBaseUrl,
  get: path => axios.get(`${Vue.prototype.$config.apiBaseUrl}${path}`).then(response => response.data),
  post: (path, data={}) => axios.post(`${Vue.prototype.$config.apiBaseUrl}${path}`, data).then(response => response.data),
  downloadViaGet(path: string, filename: string) {
    const fileDownload = require('js-file-download')
    return axios.get(`${Vue.prototype.$config.apiBaseUrl}${path}`).then(
        response => fileDownload(response.data, filename),
        Vue.prototype.$errorHandler
    )
  },
  termCodeToName(termCode: string) {
    return _.get(
      {
        'A': 'Winter',
        'B': 'Spring',
        'C': 'Summer',
        'D': 'Fall'
      },
      termCode
    )
  }
}
