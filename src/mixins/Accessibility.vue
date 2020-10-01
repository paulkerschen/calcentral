<script>
  export default {
    name: 'Accessibility',
    methods: {
      accessibilityAnnounce(message) {
        // Remove existing announcer
        var existingAnnouncer = window.document.getElementById('cc-sr-announcer')
        if (document.body.contains(existingAnnouncer)) {
          existingAnnouncer.parentNode.removeChild(existingAnnouncer)
        }

        // Add new announcer
        var announcer = window.document.createElement('div')
        var announcerAlert = window.document.createElement('p')
        var announcerHeader = window.document.createElement('h1')
        announcer.setAttribute('id', 'cc-sr-announcer')
        announcer.setAttribute('class', 'cc-visuallyhidden')
        announcerHeader.innerHTML = 'Last Page Update'
        announcerAlert.setAttribute('role', 'alert')
        announcerAlert.setAttribute('aria-live', 'assertive')
        announcerAlert.innerHTML = message
        announcer.appendChild(announcerHeader)
        announcer.appendChild(announcerAlert)
        window.document.body.appendChild(announcer)
      }
    }
  }
</script>
