<template>
  <div :class="{'cc-masthead': $currentUser.isLoggedIn && !isInIframe}">
    <SrAlert />
    <router-view />
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import Iframe from '@/mixins/Iframe'
import SrAlert from '@/components/util/SrAlert'

export default {
  name: 'BaseView',
  mixins: [Context, Iframe],
  components: {SrAlert}
}
</script>
