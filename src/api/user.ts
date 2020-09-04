import axios from 'axios'
import utils from '@/api/api-utils'

export function isUserLoggedIn() {
  const url = `${utils.apiBaseUrl()}/api/my/am_i_logged_in`;
  axios.get(url).then(response => response.data, () => null)
}

export function myStatus() {
  const url = `${utils.apiBaseUrl()}/api/my/status`;
  return axios.get(url).then(response => response.data, () => null)
}
