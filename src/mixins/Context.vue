<script>
import store from '@/store'
import Vue from 'vue'
import {mapActions, mapGetters} from 'vuex'

export default {
  name: 'Context',
  computed: {
    ...mapGetters('context', ['loading', 'screenReaderAlert'])
  },
  methods: {
    alertScreenReader(message) {
      store.dispatch('context/alertScreenReader', '')
      Vue.nextTick(() => store.dispatch('context/alertScreenReader', message))
    }
  }
}
</script>
