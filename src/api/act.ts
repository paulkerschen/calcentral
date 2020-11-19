import utils from '@/api/api-utils'

export function actAs(uid) {
  return utils.post('/act_as', {uid})
}

export function getMyStoredUsers() {
  return utils.get('/api/view_as/my_stored_users')
}

export function removeAllSavedUsers() {
  return utils.post('/delete_users/saved')
}

export function removeAllRecentUsers(uid) {
  return utils.post('/delete_users/recent', {uid})
}

export function removeSavedUser(uid) {
  return utils.post('/delete_user/saved', {uid})
}

export function searchUsers(id) {
  return utils.get(`/api/search_users/${id}`)
}

export function stopActAs() {
  return utils.post('/stop_act_as')
}

export function storeUserAsSaved(uid) {
  return utils.post('/api/view_as/store_user_as_saved', {uid})
}
