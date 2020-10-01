<template>
  <a :href="href" target="_blank">
    <slot />
    <span class="cc-outbound-link cc-visuallyhidden cc-print-hide"> (link opens new browser tab)</span>
  </a>
</template>

<script>
export default {
  name: 'OutboundLink',
  props: {
    href: {
      type: String,
      required: true
    }
  }
}
</script>
