<template>
  <div class="cc-masthead">
    <Spinner />
    <SrAlert />
    <router-view />
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import Spinner from '@/components/util/Spinner'
import SrAlert from '@/components/util/SrAlert'

export default {
  name: 'BaseView',
  components: {Spinner, SrAlert},
  mixins: [Context]
}
</script>
