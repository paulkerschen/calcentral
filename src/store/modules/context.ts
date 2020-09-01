import Vue from 'vue'

const state = {
  loading: undefined,
  screenReaderAlert: undefined
}

const getters = {
  loading: (state: any): boolean => state.loading,
  screenReaderAlert: (state: any): string => state.screenReaderAlert
}

const mutations = {
  loadingComplete: (state: any, pageTitle: string) => {
    document.title = `${pageTitle || 'UC Berkeley'} | bCourses Support`
    state.loading = false
    if (pageTitle) {
      state.screenReaderAlert = `${pageTitle} page is ready`
    }
    Vue.prototype.$putFocusNextTick('page-title')
  },
  loadingStart: (state: any) => (state.loading = true),
  setScreenReaderAlert: (state: any, alert: string) => (state.screenReaderAlert = alert)
}

const actions = {
  alertScreenReader: ({ commit }, alert) => commit('setScreenReaderAlert', alert),
  loadingComplete: ({ commit }, pageTitle) => commit('loadingComplete', pageTitle),
  loadingStart: ({ commit }) => commit('loadingStart')
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}
