<script>
  import _ from 'lodash'

  export default {
    name: 'Utils',
    methods: {
      decamelize: (str, separator=' ') => _.capitalize(str.replace(/([a-z\d])([A-Z])/g, '$1' + separator + '$2').replace(/([A-Z]+)([A-Z][a-z\d]+)/g, '$1' + separator + '$2')),
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
      pluralize: (noun, count, substitutions = {}, pluralSuffix = 's') => {
        count = count || 0
        return (`${substitutions[count] || substitutions['other'] || count} ` + (count !== 1 ? `${noun}${pluralSuffix}` : noun))
      },
      printPage(filename) {
        const previousTitle = document.title
        document.title = filename
        window.print()
        document.title = previousTitle
      },
      toInt: (value, defaultValue = null) => {
        const parsed = parseInt(value, 10)
        return Number.isInteger(parsed) ? parsed : defaultValue
      }
    }
  }
</script>
