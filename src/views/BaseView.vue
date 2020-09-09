<template>
  <div>
    <Spinner />
    <router-view />
    <Footer />
  </div>
</template>

<script>
import Context from '@/mixins/Context'
import Footer from '@/components/Footer'
import Spinner from '@/components/Spinner'

export default {
  name: 'BaseView',
  components: {Footer, Spinner},
  mixins: [Context]
}
</script>
