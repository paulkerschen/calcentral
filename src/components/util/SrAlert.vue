<template>
  <span
    v-if="screenReaderAlert"
    class="sr-only"
    aria-live="polite"
    role="alert"
  >
    {{ screenReaderAlert }}
  </span>
</template>

<script>
import Context from '@/mixins/Context'

export default {
  name: 'SrAlert',
  mixins: [Context]
}
</script>
