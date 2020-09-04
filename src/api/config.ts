import utils from '@/api/api-utils'

export function ping() {
  return utils.get('/api/ping')
}

export function getVersion() {
  return utils.get('/api/version')
}

export function serverInfo() {
  return utils.get('/api/server_info')
}
