import axios from 'axios'
import utils from '@/api/api-utils'
import Vue from 'vue'

export function devAuthLogIn(uid: string, password: string, redirect: string) {
  const config = {
    headers: {
      Authorization: `Basic ${window.btoa(uid + ':' + password)}`
    }
  }
  return axios.get(`${utils.apiBaseUrl()}/basic_auth_login?url=redirect`, config).then(data => {
    Vue.prototype.$currentUser = data
    return Vue.prototype.$currentUser
  })
}
