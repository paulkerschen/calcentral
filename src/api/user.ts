import utils from '@/api/api-utils'

export function isUserLoggedIn() {
  return utils.get('/api/my/am_i_logged_in')
}

export function myStatus() {
  return utils.get('/api/my/status')
}
