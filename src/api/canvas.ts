import utils from '@/api/api-utils'

export function externalTools() {
  return utils.get('/api/academics/canvas/external_tools')
}

export function canUserCreateSite() {
  return utils.get('/api/academics/canvas/user_can_create_site')
}

export function importUsers(userIds: string[]) {
  return utils.post('/api/academics/canvas/user_provision/user_import', {userIds})
}

export function getRoster(courseId: number) {
  return utils.get(`/api/academics/rosters/canvas/${courseId}`)
}

export function getRosterCsv(courseId: number) {
  return utils.downloadViaGet(`/api/academics/rosters/canvas/csv/${courseId}`, `course_${courseId}_rosters.csv`)
}
