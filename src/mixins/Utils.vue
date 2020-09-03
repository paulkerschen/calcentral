<script>
  import _ from 'lodash'

  export default {
    name: 'Utils',
    methods: {
      goToPath(path) {
        this.$router.push({ path }, _.noop)
      },
      oxfordJoin: arr => {
        switch(arr.length) {
          case 1: return _.head(arr)
          case 2: return `${_.head(arr)} and ${_.last(arr)}`
          default: return _.join(_.concat(_.initial(arr), ` and ${_.last(arr)}`), ', ')
        }
      },
      putFocusNextTick: (id, cssSelector) => {
        const callable = () => {
          let el = document.getElementById(id)
          el = el && cssSelector ? el.querySelector(cssSelector) : el
          el && el.focus()
          return !!el
        }
        Vue.prototype.$nextTick(() => {
          let counter = 0
          const job = setInterval(() => (callable() || ++counter > 3) && clearInterval(job), 500)
        })
      }
    }
  }
</script>
