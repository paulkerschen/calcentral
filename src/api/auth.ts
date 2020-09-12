import axios from 'axios'
import utils from '@/api/api-utils'
import Vue from 'vue'

export function devAuthLogIn(uid: string, password: string, redirect: string) {
  const url = `${utils.apiBaseUrl()}/api/auth/dev_auth`
  return axios.post(url, {
    password,
    uid,
    url: redirect
  }).then(data => {
    Vue.prototype.$currentUser = data
    return Vue.prototype.$currentUser
  })
}

export function logOut() {
  return utils.get('/logout')
}
