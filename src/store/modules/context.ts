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
  loadingComplete: (state: any, {label, focusTarget}) => {
    document.title = `${label || 'UC Berkeley'} | bCourses Support`
    state.loading = false
    if (label) {
      state.screenReaderAlert = `${label} page is ready`
    }
    if (focusTarget) {
      Vue.prototype.$putFocusNextTick(focusTarget)
    } else {
      const callable = () => {
        const elements = document.getElementsByTagName('h1')
        if (elements.length > 0) {
          elements[0].setAttribute('tabindex', '-1')
          elements[0].focus()
        }
        return elements.length > 0
      }
      Vue.prototype.$nextTick(() => {
        let counter = 0
        const job = setInterval(() => (callable() || ++counter > 3) && clearInterval(job), 500)
      })
    }
  },
  loadingStart: (state: any, label: string) => {
    state.loading = true
    state.screenReaderAlert = `${label || 'Page'} is loading...`
  },
  setScreenReaderAlert: (state: any, alert: string) => (state.screenReaderAlert = alert)
}

const actions = {
  alertScreenReader: ({ commit }, alert) => commit('setScreenReaderAlert', alert)
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}
