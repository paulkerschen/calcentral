import axios from 'axios'
import utils from '@/api/api-utils'

export function externalTools() {
  const url = `${utils.apiBaseUrl()}/api/academics/canvas/external_tools`;
  return axios.get(url).then(response => response.data, () => null)
}

export function canUserCreateSite() {
  const url = `${utils.apiBaseUrl()}/api/academics/canvas/user_can_create_site`;
  return axios.get(url).then(response => response.data, () => null)
}
