import _ from 'lodash'
import utils from '@/api/api-utils'

// Shared

export function getCourseUserRoles(canvasCourseId: string) {
  return utils.get(`/api/academics/canvas/course_user_roles/${canvasCourseId}`)
}

// Add user

export function addUser(canvasCourseId: string, ldapUserId: string, sectionId: string, role: string) {
  return utils.post(`/api/academics/canvas/course_add_user/${canvasCourseId}/add_user`, {ldapUserId, sectionId, role})
}

export function getAddUserCourseSections(canvasCourseId: string) {
  return utils.get(`/api/academics/canvas/course_add_user/${canvasCourseId}/course_sections`)
}

export function searchUsers(canvasCourseId: string, searchText: string, searchType: string) {
  return utils.get(`/api/academics/canvas/course_add_user/${canvasCourseId}/search_users?searchText=${searchText}&searchType=${searchType}`)
}

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

// Grade export

export function downloadGradeCsv(courseId: string, ccn: string, termCode: string, termYear: string, type: string, pnpCutoff: string) {
  const queryParams = [
    `ccn=${ccn}`,
    `term_cd=${termCode}`,
    `term_yr=${termYear}`,
    `type=${type}`,
    `pnp_cutoff=${pnpCutoff}`
  ].join('&')
  const filename = `egrades-${type}-${ccn}-${utils.termCodeToName(termCode)}-${termYear}-${courseId}.csv`
  return utils.downloadViaGet(`/api/academics/canvas/egrade_export/download/${courseId}.csv?${queryParams}`, filename)
}

export function getExportOptions(canvasCourseId: string) {
  return utils.get(`/api/academics/canvas/egrade_export/options/${canvasCourseId}`)
}

export function getExportJobStatus(canvasCourseId: string, jobId: string) {
  return utils.get(`/api/academics/canvas/egrade_export/status/${canvasCourseId}?jobId=${jobId}`)
}

export function prepareGradesCacheJob(canvasCourseId: string) {
  return utils.post(`/api/academics/canvas/egrade_export/prepare/${canvasCourseId}`)
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
export function courseCreate(adminActingAs, adminByCcns, adminTermSlug, ccns, siteAbbreviation, siteName, termSlug) {
  return utils.post('/api/academics/canvas/course_provision/create', {
    admin_acting_as: adminActingAs,
    admin_by_ccns: adminByCcns,
    admin_term_slug: adminTermSlug,
    ccns,
    siteAbbreviation,
    siteName,
    termSlug
  })
}

export function createProjectSite(name) {
  return utils.post('/api/academics/canvas/project_provision/create',{name})
}

export function courseProvisionJobStatus(jobId) {
  return utils.get(`/api/academics/canvas/course_provision/status?jobId=${jobId}`)

}

export function getSiteCreationAuthorizations() {
  return utils.get('/api/academics/canvas/site_creation/authorizations')
}

export function getCourseProvisioningMetadata() {
  return utils.get('/api/academics/canvas/course_provision')
}

export function getCourseSections(canvasCourseId) {
  return utils.get(`/api/academics/canvas/course_provision/sections_feed/${canvasCourseId}`)
}

export function getSections(
  adminActingAs: string,
  adminByCcns: number[],
  adminMode: string,
  currentSemester: string,
  isAdmin: boolean
) {
  let feedUrl = '/api/academics/canvas/course_provision'
  if (isAdmin) {
    if (adminMode === 'act_as' && adminActingAs) {
      feedUrl = '/api/academics/canvas/course_provision_as/' + adminActingAs
    } else if ((adminMode !== 'act_as') && adminByCcns) {
      feedUrl = `/api/academics/canvas/course_provision?admin_term_slug=${currentSemester}`
      _.each(adminByCcns, ccn => feedUrl += `&admin_by_ccns[]=${ccn}`)
    }
  }
  return utils.get(feedUrl)
}

// User provision

export function canUserCreateSite() {
  return utils.get('/api/academics/canvas/user_can_create_site')
}

export function importUsers(userIds: string[]) {
  return utils.post('/api/academics/canvas/user_provision/user_import', {userIds})
}

// Webcasts

export function getWebcasts(canvasCourseId: string) {
  return utils.get(`/api/canvas/media/${canvasCourseId}`)
}
