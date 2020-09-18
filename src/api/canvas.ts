import axios from 'axios'
import utils from '@/api/api-utils'

export function externalTools() {
  return utils.get('/api/academics/canvas/external_tools')
}

export function canUserCreateSite() {
  return utils.get('/api/academics/canvas/user_can_create_site')
}

export function importUsers(userIds: string[]) {
  return axios.post(`${utils.apiBaseUrl()}/api/academics/canvas/user_provision/user_import`, {
    userIds
  }).then(response => response.data, () => null)
}
