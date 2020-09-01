import BaseView from '@/views/BaseView.vue'
import Home from '@/views/Home.vue'
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
      path: '/',
      component: BaseView,
      children: [
        {
          path: '/home',
          component: Home
        }
      ]
    }
  ]
})

export default router
