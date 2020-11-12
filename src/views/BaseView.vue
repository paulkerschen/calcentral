<template>
  <div :class="{'cc-masthead': $currentUser.isLoggedIn && !isInIframe}">
    <Spinner />
    <SrAlert />
    <router-view />
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import Iframe from '@/mixins/Iframe'
import Spinner from '@/components/util/Spinner'
import SrAlert from '@/components/util/SrAlert'

export default {
  name: 'BaseView',
  mixins: [Context, Iframe],
  components: {Spinner, SrAlert}
}
</script>
