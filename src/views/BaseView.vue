<template>
  <div class="bg-white w-50">
    <div>
      <router-view />
    </div>
    <div>
      <Footer />
    </div>
  </div>
</template>

<script>
import Footer from '@/components/Footer'

export default {
  name: 'BaseView',
  components: { Footer }
}
</script>
