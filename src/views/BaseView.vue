<template>
  <div>
    <Spinner />
    <router-view />
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import Spinner from '@/components/Spinner'

export default {
  name: 'BaseView',
  components: {Spinner},
  mixins: [Context]
}
</script>
