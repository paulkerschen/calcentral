import axios from 'axios'
import utils from '@/api/api-utils'

export function actAs(uid) {
  return axios.post(`${utils.apiBaseUrl()}/act_as`, {
    uid
  }).then(response => response.data, () => null)
}

export function getMyStoredUsers() {
  return utils.get('/api/view_as/my_stored_users')
}

export function removeAllSavedUsers() {
  return axios.post(`${utils.apiBaseUrl()}/delete_users/saved`).then(response => response.data, () => null)
}

export function removeAllRecentUsers(uid) {
  return axios.post(`${utils.apiBaseUrl()}/delete_users/recent`, {
    uid
  }).then(response => response.data, () => null)
}

export function removeSavedUser(uid) {
  return axios.post(`${utils.apiBaseUrl()}/delete_user/saved`, {
    uid
  }).then(response => response.data, () => null)
}

export function searchUsers(id) {
  return utils.get(`/api/search_users/${id}`)
}

export function stopActAs() {
  return axios.post(`${utils.apiBaseUrl()}/stop_act_as`).then(response => response.data, () => null)
}

export function storeUserAsRecent(uid) {
  return axios.post(`${utils.apiBaseUrl()}/api/view_as/store_user_as_recent`, {
    uid
  }).then(response => response.data, () => null)
}

export function storeUserAsSaved(uid) {
  return axios.post(`${utils.apiBaseUrl()}/api/view_as/store_user_as_saved`, {
    uid
  }).then(response => response.data, () => null)
}
