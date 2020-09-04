import axios from 'axios'
import utils from '@/api/api-utils'

export function ping() {
  const url = `${utils.apiBaseUrl()}/api/ping`;
  return axios.get(url).then(response => response.data, () => null)
}

export function getVersion() {
  const url = `${utils.apiBaseUrl()}/api/version`;
  return axios.get(url).then(response => response.data, () => null)
}

export function serverInfo() {
  const url = `${utils.apiBaseUrl()}/api/server_info`;
  return axios.get(url).then(response => response.data, () => null)
}
