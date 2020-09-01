import _ from 'lodash'
import auth from './auth'
import BaseView from '@/views/BaseView.vue'
import Home from '@/views/Home.vue'
import Login from '@/views/Login.vue'
import NotFound from '@/views/NotFound.vue'
import Router from 'vue-router'
import Vue from 'vue'

Vue.use(Router)

const router = new Router({
  mode: 'history',
  routes: [
    {
      path: '/',
      redirect: '/home'
    },
    {
      beforeEnter: (to: any, from: any, next: any) => {
        const currentUser = Vue.prototype.$currentUser
        if (currentUser.isLoggedIn) {
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
      component: Login,
      meta: {
        title: 'Welcome'
      }
    },
    {
      path: '/',
      beforeEnter: auth.requiresAdmin,
      component: BaseView,
      children: [
        {
          component: Home,
          name: 'home',
          path: '/home',
          meta: {
            title: 'Home'
          }
        }
      ]
    },
    {
      path: '/404',
      component: NotFound,
      meta: {
        title: 'Page not found'
      }
    },
    {
      path: '*',
      redirect: '/404'
    }
  ]
})

router.afterEach((to: any) => {
  const title = _.get(to, 'meta.title') || _.capitalize(to.name) || 'Welcome'
  document.title = `${title} | BOA`
})

export default router
