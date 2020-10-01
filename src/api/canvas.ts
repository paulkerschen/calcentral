import utils from '@/api/api-utils'

// External tools

export function externalTools() {
  return utils.get('/api/academics/canvas/external_tools')
}

// Mailing lists: endpoints with minimal permissions, to be used by instructors

export function createSiteMailingList(canvasCourseId: string) {
  return utils.post(`/api/academics/canvas/mailing_list/${canvasCourseId}/create`)
}

export function getSiteMailingList(canvasCourseId: string) {
  return utils.get(`/api/academics/canvas/mailing_list/${canvasCourseId}`)
}

// Mailing lists: endpoints requiring admin permissions

export function getSiteMailingListAdmin(canvasCourseId: string) {
  return utils.get(`/api/academics/canvas/mailing_lists/${canvasCourseId}`)
}

export function createSiteMailingListAdmin(canvasCourseId: string, list: any) {
  return utils.post(`/api/academics/canvas/mailing_lists/${canvasCourseId}/create`, {listName: list.name})
}

export function populateSiteMailingList(canvasCourseId: string) {
  return utils.post(`/api/academics/canvas/mailing_lists/${canvasCourseId}/populate`)
}

// Rosters

export function getRoster(courseId: number) {
  return utils.get(`/api/academics/rosters/canvas/${courseId}`)
}

export function getRosterCsv(courseId: number) {
  return utils.downloadViaGet(`/api/academics/rosters/canvas/csv/${courseId}`, `course_${courseId}_rosters.csv`)
}

// Site creation

export function createProjectSite(name) {
  return utils.post('/api/academics/canvas/project_provision/create',{name})
}

export function getSiteCreationAuthorizations() {
  return utils.get('/api/academics/canvas/site_creation/authorizations')
}

export function getCourseSections(canvasCourseId) {
  return utils.get(`/api/academics/canvas/course_provision/sections_feed/${canvasCourseId}`)
}

// User provision

export function canUserCreateSite() {
  return utils.get('/api/academics/canvas/user_can_create_site')
}

export function importUsers(userIds: string[]) {
  return utils.post('/api/academics/canvas/user_provision/user_import', {userIds})
}
