import _ from 'lodash'
import auth from './auth'
import BaseView from '@/views/BaseView.vue'
import CourseGradeExport from '@/components/bcourses/CourseGradeExport.vue'
import CreateCourseSite from '@/views/CreateCourseSite.vue'
import CreateProjectSite from '@/views/CreateProjectSite.vue'
import EmbeddedLti from '@/views/EmbeddedLti.vue'
import Error from '@/views/Error.vue'
import Login from '@/views/Login.vue'
import NotFound from '@/views/NotFound.vue'
import Roster from '@/views/Roster.vue'
import Router from 'vue-router'
import SiteCreation from '@/views/SiteCreation.vue'
import SiteMailingList from '@/components/bcourses/SiteMailingList.vue'
import SiteMailingLists from '@/components/bcourses/SiteMailingLists.vue'
import StandaloneLti from '@/views/StandaloneLti.vue'
import Toolbox from '@/views/Toolbox.vue'
import UserProvision from '@/components/bcourses/UserProvision.vue'
import Vue from 'vue'

Vue.use(Router)

const router = new Router({
  mode: 'history',
  routes: [
    {
      path: '/',
      redirect: '/toolbox'
    },
    {
      beforeEnter: (to: any, from: any, next: any) => {
        const currentUser = Vue.prototype.$currentUser
        if (currentUser && currentUser.isLoggedIn) {
          if (_.trim(to.query.redirect)) {
            next(to.query.redirect)
          } else {
            next({ path: '/404' })
          }
        } else {
          next()
        }
      },
      path: '/login',
      component: BaseView,
      children: [
        {
          component: Login,
          path: '/login',
          meta: {
            title: 'Welcome'
          }
        }
      ]
    },
    {
      path: '/',
      beforeEnter: auth.requiresAuthenticated,
      component: BaseView,
      children: [
        {
          component: Toolbox,
          name: 'toolbox',
          path: '/toolbox',
          meta: {
            title: 'Toolbox'
          }
        },
        {
          component: StandaloneLti,
          path: '/canvas',
          children: [
            {
              component: CourseGradeExport,
              path: '/canvas/course_grade_export/:id',
              meta: {
                title: 'E-Grade Export'
              }
            },
            {
              component: Roster,
              path: '/canvas/rosters/:id',
              meta: {
                title: 'bCourses Roster Photos'
              }
            },
            {
              component: SiteCreation,
              path: '/canvas/site_creation',
              meta: {
                title: 'bCourses Site Creation'
              }
            },
            {
              component: CreateCourseSite,
              path: '/canvas/create_course_site',
              meta: {
                title: 'Create a Course Site'
              }
            },
            {
              component: CreateProjectSite,
              path: '/canvas/create_project_site',
              meta: {
                title: 'Create a Project Site'
              }
            },
            {
              component: SiteMailingList,
              path: '/canvas/site_mailing_list/:id',
              meta: {
                title: 'bCourses Mailing List'
              }
            },
            {
              component: SiteMailingLists,
              path: '/canvas/site_mailing_lists',
              meta: {
                title: 'bCourses Site Mailing Lists'
              }
            },
            {
              component: UserProvision,
              path: '/canvas/user_provision',
              meta: {
                title: 'bCourses User Provision'
              }
            }
          ]
        },
        {
          component: EmbeddedLti,
          path: '/canvas/embedded',
          children: [
            {
              component: CourseGradeExport,
              path: '/canvas/embedded/course_grade_export'
            },
            {
              component: Roster,
              path: '/canvas/embedded/rosters'
            },
            {
              component: SiteCreation,
              path: '/canvas/embedded/site_creation'
            },
            {
              component: SiteMailingList,
              path: '/canvas/embedded/site_mailing_list'
            },
            {
              component: SiteMailingLists,
              path: '/canvas/embedded/site_mailing_lists'
            },
            {
              component: UserProvision,
              path: '/canvas/embedded/user_provision'
            }
          ]
        }
      ]
    },
    {
      path: '/',
      component: BaseView,
      children: [
        {
          beforeEnter: (to: any, from: any, next: any) => {
            to.params.m = to.redirectedFrom
            next()
          },
          path: '/404',
          component: NotFound,
          meta: {
            title: 'Page not found'
          }
        },
        {
          path: '/error',
          component: Error,
          meta: {
            title: 'Error'
          }
        }
      ]
    },
    {
      path: '*',
      redirect: '/404'
    }
  ]
})

router.afterEach((to: any) => {
  const title = _.get(to, 'meta.title') || _.capitalize(to.name) || 'Welcome'
  document.title = `${title} | Junction`
})

export default router
